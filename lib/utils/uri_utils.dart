import 'package:flutter/material.dart';

class UriUtils {
  static Uri fromUri({@required Uri uri, String scheme, String userInfo, String host, int port, String path}) => Uri(
    scheme: scheme??uri.scheme, 
    userInfo: userInfo??uri.userInfo, 
    host: host??uri.host, 
    port: port??uri.port, 
    path: path??uri.path
  );
}