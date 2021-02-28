import 'package:flutter/material.dart';
import 'package:string_validator/string_validator.dart';

class UriUtils {
  static Uri fromUri({
    @required Uri uri,
    String scheme,
    String userInfo,
    String host,
    int port,
    String path,
  }) =>
      Uri(
        scheme: scheme ?? uri.scheme,
        userInfo: userInfo ?? uri.userInfo,
        host: host ?? uri.host,
        port: port ?? uri.port,
        path: path ?? uri.path,
      );

  static Uri fromPathSegments(
      {@required Uri uri, @required List<String> pathSegments}) {
    String path = "";
    pathSegments.forEach((element) {
      path = UriUtils.chainPathSegments(path, element);
    });
    // do not double encode here because paths are already double encoded
    return UriUtils.fromUri(uri: uri, path: path);
  }

  static String chainPathSegments(String first, String second) {
    if (!first.endsWith("/")) {
      first = "$first/";
    }

    if (second.startsWith("/")) {
      second = ltrim(second, "/");
    }

    return "$first$second";
  }

  static Uri getRootFromUri(Uri uri) => UriUtils.fromUri(uri: uri, path: "/");

  static Uri fromUriPathSegments(Uri uri, int index) {
    String path = "/";
    for (int i = 0; i <= index; i++) {
      path += uri.pathSegments[i] + "/";
    }
    // in cases where we have encoded chars in the folder name we have to double encode to make sure we do not change the meaning
    return UriUtils.fromUri(uri: uri, path: Uri.encodeFull(path));
  }

  static String getNameFromUri(Uri uri) {
    if (uri.pathSegments.isEmpty) {
      return uri.host;
    }

    //resolving any encoded chars in the name of a file/folder to improve readability
    if (uri.pathSegments.last.isNotEmpty) {
      return Uri.decodeFull(uri.pathSegments.last);
    }

    return Uri.decodeFull(uri.pathSegments[uri.pathSegments.length - 2]);
  }
}
