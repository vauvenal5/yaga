import 'package:nextcloud/nextcloud.dart';

class NextCloudClientFactory {
  NextCloudClient createNextCloudClient(
          Uri host, String username, String password) =>
      NextCloudClient.withCredentials(
        host,
        username,
        password,
      );
}
