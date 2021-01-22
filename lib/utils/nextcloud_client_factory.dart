import 'dart:io';

import 'package:nextcloud/nextcloud.dart';

class NextCloudClientFactory {
  final defaultHeaders = <String, String>{
    HttpHeaders.userAgentHeader: "Nextcloud Yaga",
  };

  //todo: is this really the right place for this?
  String get userAgent => defaultHeaders[HttpHeaders.userAgentHeader];

  NextCloudClient createNextCloudClient(
    Uri host,
    String username,
    String password,
  ) =>
      NextCloudClient.withCredentials(
        host,
        username,
        password,
        defaultHeaders: defaultHeaders,
      );

  NextCloudClient createUnauthenticatedClient(Uri host) =>
      NextCloudClient.withoutLogin(
        host,
        defaultHeaders: defaultHeaders,
      );
}
