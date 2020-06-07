
import 'dart:convert';
import 'dart:typed_data';

import 'package:nextcloud/nextcloud.dart';

class NextCloudService {
  NextCloudClient _client;

  void login(String host, String username, String password) {
    this._client = NextCloudClient(host, username, password);
  }

  void logout() {
    this._client = null;
  }

  bool isLoggedIn() => _client==null ? false : true;

  void listFiles(String path) {
    this._client.webDav.ls("files/svidenov/").catchError((error) {
      print(error);
      return Future.error(error);
    }).asStream().listen((event) {
      event.forEach((element) {
        print(element);
        // print(element.name+":"+element.mimeType??"");
      });
    });
  }

  Future<Uint8List> getAvatar(user) {
    print("getting avatar: "+user);
    return this._client.avatar.getAvatar(user, 100)
      .then((value) => base64.decode(value));
  }
}