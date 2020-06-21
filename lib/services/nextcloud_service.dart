
import 'dart:convert';
import 'dart:typed_data';

import 'package:rxdart/rxdart.dart';
import 'package:nextcloud/nextcloud.dart';
import 'package:string_validator/string_validator.dart';
import 'package:yaga/model/nc_file.dart';
import 'package:yaga/services/file_provider_service.dart';
import 'package:yaga/services/service.dart';

class NextCloudService with Service<NextCloudService> implements FileProviderService<NextCloudService> {
  final String scheme = "nc";
  Uri _host;
  NextCloudClient _client;

  void login(Uri host, String username, String password) {
    this._host = host;
    this._client = NextCloudClient(_host.toString(), username, password);
  }

  void logout() {
    this._client = null;
  }

  bool isLoggedIn() => _client==null ? false : true;

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
      // file.path = webDavFile.path.replaceFirst("/$basePath", "");
      return file;
    });//.toList --> should this return a Future<List> since the data is actually allready downloaded?
  }

  Future<Uint8List> getAvatar(user) {
    print("getting avatar: "+user);
    return this._client.avatar.getAvatar(user, 100)
      .then((value) => base64.decode(value));
  }

  Future<Uint8List> getPreview(String path) {
    return this._client.preview.getPreview(Uri.decodeComponent(path.replaceFirst("nc:", "")), 128, 128)
    .catchError((err) {
      print("Could not load preview for $path");
      return err;
    });
  }

  Future<Uint8List> downloadImage(String path) {
    String basePath = "files/${_client.username}";
    return this._client.webDav.download(basePath+path);
  }

  Uri getOrigin() {
    return Uri(scheme: this.scheme, userInfo: _client.username, host: _host.host);
  }
}