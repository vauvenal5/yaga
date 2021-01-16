class NextCloudLoginDataKeys {
  static const String server = "server";
  static const String user = "user";
  static const String password = "password";
  static const String id = "id";
  static const String displayName = "displayName";
}

class NextCloudLoginData {
  final Uri server;
  final String user;
  final String password;
  final String id;
  final String displayName;

  NextCloudLoginData(
    this.server,
    this.user,
    this.password, {
    this.id = "",
    this.displayName = "",
  });

  factory NextCloudLoginData.empty() => NextCloudLoginData(
        null,
        "",
        "",
      );
}
