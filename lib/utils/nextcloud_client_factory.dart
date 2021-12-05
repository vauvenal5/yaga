import 'dart:io';

import 'package:nextcloud/nextcloud.dart';
import 'package:yaga/utils/self_signed_cert_handler.dart';

class NextCloudClientFactory {
  final defaultHeaders = <String, String>{
    HttpHeaders.userAgentHeader: "Nextcloud Yaga",
  };

  // we do not actually need the SelfSignedCertHandler,
  // however we have to make sure it was initialized
  // before allowing anyone to create Nextcloud clients
  // ignore: avoid_unused_constructor_parameters
  NextCloudClientFactory(SelfSignedCertHandler handler);

  //todo: is this really the right place for this?
  String get userAgent => defaultHeaders[HttpHeaders.userAgentHeader]!;

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
