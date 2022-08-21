class NextCloudLoginDataKeys {
  static const String server = "server";
  static const String user = "user";
  static const String password = "password";
  static const String id = "id";
  static const String displayName = "displayName";
}

class NextCloudLoginData {
  final Uri? server;
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

  factory NextCloudLoginData.empty() => NextCloudLoginData(null, "", "",);

  //todo: Background: use auto-generation for formJson/toJson?
  NextCloudLoginData.fromJson(Map<String, dynamic> json)
      : server = Uri.parse(json[NextCloudLoginDataKeys.server] as String),
        user = json[NextCloudLoginDataKeys.user] as String,
        password = json[NextCloudLoginDataKeys.password] as String,
        id = json[NextCloudLoginDataKeys.id] as String,
        displayName = json[NextCloudLoginDataKeys.displayName] as String;

  Map<String, dynamic> toJson() {
    return {
      NextCloudLoginDataKeys.server: server.toString(),
      NextCloudLoginDataKeys.user: user,
      NextCloudLoginDataKeys.password: password,
      NextCloudLoginDataKeys.id: id,
      NextCloudLoginDataKeys.displayName: displayName,
    };
  }
}
