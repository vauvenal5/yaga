
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
    .map((webDavFile) {
      NcFile file = NcFile();
      file.isDirectory = webDavFile.isDirectory;
      file.name = webDavFile.name;
      file.path = "nc:"+webDavFile.path.replaceFirst("/remote.php/dav/"+basePath, "");
      return file;
    });
  }

  Future<Uint8List> getAvatar(user) {
    print("getting avatar: "+user);
    return this._client.avatar.getAvatar(user, 100)
      .then((value) => base64.decode(value));
  }
}