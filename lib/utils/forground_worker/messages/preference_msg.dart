import 'package:yaga/model/preference.dart';
import 'package:yaga/utils/forground_worker/messages/message.dart';

class PreferenceMsg extends Message {
  final Preference preference;

  PreferenceMsg(String key, this.preference) : super(key);
}