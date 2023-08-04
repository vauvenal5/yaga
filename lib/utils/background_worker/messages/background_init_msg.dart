import 'package:yaga/model/nc_login_data.dart';

class BackgroundInitMsg {
  static const String _jsonLastLoginData = "lastLoginData";
  static const String _jsonFingerprint = "fingerprint";

  final NextCloudLoginData lastLoginData;
  final String fingerprint;

  BackgroundInitMsg(this.lastLoginData, this.fingerprint);

  BackgroundInitMsg.fromJson(Map<String, dynamic> json)
      : lastLoginData = NextCloudLoginData.fromJson(
          json[_jsonLastLoginData] as Map<String, dynamic>,
        ),
        fingerprint = json[_jsonFingerprint] as String;

  Map<String, dynamic> toJson() {
    return {
      _jsonLastLoginData: lastLoginData.toJson(),
      _jsonFingerprint: fingerprint,
    };
  }
}
