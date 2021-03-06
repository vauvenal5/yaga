import 'dart:convert';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:rxdart/rxdart.dart';
import 'package:nextcloud/nextcloud.dart';
import 'package:yaga/model/nc_file.dart';
import 'package:yaga/model/nc_login_data.dart';
import 'package:yaga/model/nc_origin.dart';
import 'package:yaga/services/file_provider_service.dart';
import 'package:yaga/services/service.dart';
import 'package:yaga/utils/forground_worker/isolateable.dart';
import 'package:yaga/utils/forground_worker/messages/init_msg.dart';
import 'package:yaga/utils/nextcloud_client_factory.dart';
import 'package:yaga/utils/uri_utils.dart';

class NextCloudService
    with Service<NextCloudService>, Isolateable<NextCloudService>
    implements FileProviderService<NextCloudService> {
  //todo: it will probably be best to replace nc with https since it does not bring any actual advantage
  // --> however this is a breaking change
  final String scheme = "nc";
  NcOrigin _origin;
  NextCloudClient _client;
  NextCloudClientFactory nextCloudClientFactory;

  NextCloudService(this.nextCloudClientFactory);

  Future<NextCloudService> initIsolated(
    InitMsg init,
    SendPort isolateToMain,
  ) async {
    if (init.lastLoginData.server != null) {
      await this.login(init.lastLoginData);
    }
    return this;
  }

  Future<NcOrigin> login(NextCloudLoginData loginData) async {
    //todo: can we get rid of the client factory?
    this._client = this.nextCloudClientFactory.createNextCloudClient(
          loginData.server,
          loginData.user,
          loginData.password,
        );

    UserData userData;

    if (loginData.id == "" || loginData.displayName == "") {
      userData = await this._client.user.getUser().catchError(_logAndRethrow);
    }

    this._origin = NcOrigin(
      UriUtils.fromUri(uri: loginData.server, scheme: this.scheme),
      userData?.id ?? loginData.id,
      userData?.displayName ?? loginData.displayName,
      loginData.user,
    );

    //todo: why is logging here not possible?

    return this._origin;
  }

  void logout() {
    this._client = null;
  }

  bool isLoggedIn() => _client == null ? false : true;

  @override
  Stream<NcFile> list(Uri dir) {
    logger.info("Listing ${dir.toString()}");
    logger.info("NcOrigin: ${_origin.userEncodedDomainRoot}");
    return this
        ._client
        .webDav
        .ls(dir.path)
        //todo: this will improve responsiveness in case of a bad connection but it can not be used as long
        // as we are using the sync manager for deletes and not the activity log.
        // .catchError((err) {
        //   _logError(err);
        //   return <WebDavFile>[];
        // })
        .asStream()
        .flatMap((value) => Stream.fromIterable(value))
        .where(
          (event) => event.isDirectory || event.mimeType.startsWith("image"),
        )
        .map((webDavFile) {
      logger.info("Mapping ${webDavFile.path}");
      //todo: here we are hiding the origin path, if any, because we are not interested in it, the much bigger problem is:
      // we cannot assume that the origin is depictable by url.host
      // furthermore for identifing the upstream of a file we actually need an origin-url + username
      // since, when adding multi user support in future, in theory you can have multiple users on the same cloud
      // to properly be able to identify the origin of a NcFile we need to split the information currently stored in the uri property in three:
      // file.origin: Uri
      // file.username: String
      // file.path: String/Uri (not sure yet)
      // file.origin + file.username can identify the NextCloudClient
      // file.path represents only the relative path of that file
      // --> however, we can not simply substitute the [NcFile.uri] field as long as the [MppingManager] has not been reworked
      // --> the [MappingManager] needs now to be able to map [NcLocations(NcOrigin+Path)] to each other and not simply Urls
      // --> this however requires a rather big refactoring of the [MappingManager] including persistance
      Uri uri = UriUtils.fromUri(
        uri: origin.userEncodedDomainRoot,
        path: webDavFile.path,
      );

      NcFile file = webDavFile.isDirectory
          ? NcFile.directory(uri, webDavFile.name)
          : NcFile.file(uri, webDavFile.name, webDavFile.mimeType);
      file.lastModified = webDavFile.lastModified;

      return file;
    }).doOnError((error, stacktrace) {
      _logError(error, stacktrace: stacktrace);
    });
    //.toList --> todo: should this return a Future<List> since the data is actually allready downloaded?
  }

  Future<Uint8List> getAvatar() => this
      ._client
      .avatar
      .getAvatar(origin.username, 100)
      .catchError(_logAndRethrow)
      .then((value) => base64.decode(value));

  Future<Uint8List> getPreview(Uri file) {
    String path = Uri.decodeComponent(file.path);
    logger.fine("Fetching preview $path");
    //todo: think about image sizes vs in code scaling
    return this
        ._client
        .preview
        .getPreviewByPath(path, 128, 128)
        .catchError(_logAndRethrow);
    //todo: implement proper error handling
    // .catchError((err) {
    //   print("Could not load preview for $path");
    //   return err;
    // });
  }

  Future<Uint8List> downloadImage(Uri file) =>
      this._client.webDav.download(file.path).catchError(_logAndRethrow);

  NcOrigin get origin => _origin;

  //todo: should we consider adding an [isLocal] property to NcOrigin?
  bool isUriOfService(Uri uri) => uri.scheme == this.scheme;

  Future<NcFile> deleteFile(NcFile file) => this
      ._client
      .webDav
      .delete(file.uri.path)
      .catchError(_logAndRethrow)
      .then((_) => file);

  Future<NcFile> copyFile(NcFile file, Uri destination, bool overwrite) => this
      ._client
      .webDav
      .copy(
        file.uri.path,
        UriUtils.chainPathSegments(destination.path, file.name),
        overwrite: overwrite,
      )
      .catchError(_logAndRethrow)
      .then((_) => file);

  Future<NcFile> moveFile(NcFile file, Uri destination, bool overwrite) => this
      ._client
      .webDav
      .move(
        file.uri.path,
        UriUtils.chainPathSegments(destination.path, file.name),
        overwrite: overwrite,
      )
      .catchError(_logAndRethrow)
      .then((_) => file);

  void _logAndRethrow(dynamic err) {
    _logError(err);
    throw err;
  }

  void _logError(dynamic err, {dynamic stacktrace}) {
    if (err is RequestException) {
      logger.severe("Nextcloud url: ${err.url}");
      logger.severe("Nextcloud method: ${err.method}");
      logger.severe("Nextcloud code: ${err.statusCode}");
      logger.severe("Nextcloud body: ${err.body}");
      return;
    }

    logger.severe(err, err, stacktrace);
  }
}
