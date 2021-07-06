import 'package:yaga/model/nc_login_data.dart';
import 'package:yaga/utils/forground_worker/messages/message.dart';

class LoginStateMsg extends Message {
  final NextCloudLoginData loginData;

  LoginStateMsg(String key, this.loginData) : super(key);
}
