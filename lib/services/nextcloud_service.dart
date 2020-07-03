
import 'dart:convert';
import 'dart:typed_data';

import 'package:rxdart/rxdart.dart';
import 'package:nextcloud/nextcloud.dart';
import 'package:string_validator/string_validator.dart';
import 'package:yaga/model/nc_file.dart';
import 'package:yaga/services/file_provider_service.dart';
import 'package:yaga/services/service.dart';
import 'package:yaga/utils/nextcloud_client_factory.dart';

class NextCloudService with Service<NextCloudService> implements FileProviderService<NextCloudService> {
  final String scheme = "nc";
  Uri _host;
  NextCloudClient _client;
  NextCloudClientFactory nextCloudClientFactory;

  NextCloudService(this.nextCloudClientFactory);

  void login(Uri host, String username, String password) {
    this._host = host;
    this._client = this.nextCloudClientFactory.createNextCloudClient(_host.toString(), username, password);
  }

  void logout() {
    this._client = null;
  }

  bool isLoggedIn() => _client==null ? false : true;

  String get username => _client.username;

  String get host => _host.host;

  @override
  Stream<NcFile> list(Uri dir) {
    String basePath = "files/${_client.username}";
    return this._client.webDav.ls(basePath+dir.path).asStream()
    .flatMap((value) => Stream.fromIterable(value))
    .where((event) => event.isDirectory || event.mimeType.startsWith("image"))
    .map((webDavFile) {
      NcFile file = NcFile();
      file.isDirectory = webDavFile.isDirectory;
      file.lastModified = webDavFile.lastModified;
      file.name = webDavFile.name;
      var path = rtrim(webDavFile.path.replaceFirst("/$basePath", ""), "/");
      file.uri = Uri(scheme: this.scheme, userInfo: _client.username, host: _host.host, path: path);
      return file;
    });//.toList --> should this return a Future<List> since the data is actually allready downloaded?
  }

  Future<Uint8List> getAvatar() => this._client.avatar.getAvatar(_client.username, 100).then((value) => base64.decode(value));

  Future<Uint8List> getPreview(Uri file) {
    String path = Uri.decodeComponent(file.path);
    return this._client.preview.getPreview(path, 128, 128);
    //todo: implement proper error handling
    // .catchError((err) {
    //   print("Could not load preview for $path");
    //   return err;
    // });
  }

  Future<Uint8List> downloadImage(Uri file) {
    String basePath = "files/${_client.username}";
    return this._client.webDav.download(basePath+file.path);
  }

  Uri getOrigin() {
    return Uri(scheme: this.scheme, userInfo: _client.username, host: _host.host);
  }

  Uri getRoot() {
    return Uri(scheme: this.scheme, userInfo: _client.username, host: _host.host, path: "/");
  }

  bool isUriOfService(Uri uri) => uri.scheme == this.scheme;
}