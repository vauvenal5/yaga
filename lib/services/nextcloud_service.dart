
import 'dart:convert';
import 'dart:typed_data';

import 'package:rxdart/rxdart.dart';
import 'package:nextcloud/nextcloud.dart';
import 'package:yaga/model/nc_file.dart';

class NextCloudService {
  NextCloudClient _client;

  void login(String host, String username, String password) {
    this._client = NextCloudClient(host, username, password);
  }

  void logout() {
    this._client = null;
  }

  bool isLoggedIn() => _client==null ? false : true;

  Stream<NcFile> listFiles(String path) {
    String basePath = "files/${_client.username}";
    return this._client.webDav.ls(basePath+path).asStream()
    .flatMap((value) => Stream.fromIterable(value))
    .where((event) => event.isDirectory || event.mimeType.startsWith("image"))
    .map((webDavFile) {
      NcFile file = NcFile();
      file.isDirectory = webDavFile.isDirectory;
      file.name = webDavFile.name;
      file.path = webDavFile.path.replaceFirst("/$basePath", "");
      return file;
    });//.toList --> should this return a Future<List> since the data is actually allready downloaded?
  }

  Future<Uint8List> getAvatar(user) {
    print("getting avatar: "+user);
    return this._client.avatar.getAvatar(user, 100)
      .then((value) => base64.decode(value));
  }

  Future<Uint8List> getPreview(String path) {
    return this._client.preview.getPreview(path.replaceFirst("nc:", ""), 128, 128);
  }
}