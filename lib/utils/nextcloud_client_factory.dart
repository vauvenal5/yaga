import 'package:nextcloud/nextcloud.dart';
import 'package:yaga/utils/self_signed_cert_handler.dart';

class NextCloudClientFactory {
  // we do not actually need the SelfSignedCertHandler,
  // however we have to make sure it was initialized
  // before allowing anyone to create Nextcloud clients
  // ignore: avoid_unused_constructor_parameters
  NextCloudClientFactory(SelfSignedCertHandler handler);

  //todo: is this really the right place for this?
  String get userAgent => "Nextcloud Yaga";

  NextcloudClient createNextCloudClient(
    Uri host,
    String username,
    String password,
  ) =>
      NextcloudClient(
        host,
        loginName: username,
        password: password,
        userAgentOverride: userAgent,

      );

  NextcloudClient createUnauthenticatedClient(Uri host) =>
      NextcloudClient(
        host,
        userAgentOverride: userAgent,
      );
}
