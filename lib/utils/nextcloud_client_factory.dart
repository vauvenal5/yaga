import 'package:nextcloud/nextcloud.dart';

class NextCloudClientFactory {
  NextCloudClient createNextCloudClient(String host, String username, String password) => NextCloudClient(host, username, password);
}