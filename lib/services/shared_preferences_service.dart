import 'package:shared_preferences/shared_preferences.dart';
import 'package:yaga/model/preferences/preference.dart';
import 'package:yaga/model/preferences/serializable_preference.dart';
import 'package:yaga/services/service.dart';

class SharedPreferencesService extends Service<SharedPreferencesService> {
  SharedPreferences _instance;

  @override
  Future<SharedPreferencesService> init() async {
    _instance = await SharedPreferences.getInstance();
    return this;
  }

  Future<bool> removePreference(Preference pref) => _instance.remove(pref.key);

  Future<bool> savePreferenceToString(
          SerializablePreference<String, dynamic, dynamic> pref) =>
      _instance.setString(pref.key, pref.serialize());

  P loadPreferenceFromString<
          P extends SerializablePreference<String, dynamic, dynamic>>(P pref) =>
      pref.deserialize(_instance.getString(pref.key));

  Future<bool> savePreferenceToBool(
          SerializablePreference<bool, dynamic, dynamic> pref) =>
      _instance.setBool(pref.key, pref.serialize());

  P loadPreferenceFromBool<
          P extends SerializablePreference<bool, dynamic, dynamic>>(P pref) =>
      pref.deserialize(_instance.getBool(pref.key));

  Future<bool> savePreferenceToStringList(
          SerializablePreference<List<String>, dynamic, dynamic> pref) =>
      _instance.setStringList(pref.key, pref.serialize());

  P loadPreferenceFromStringList<
              P extends SerializablePreference<List<String>, dynamic, dynamic>>(
          P pref) =>
      pref.deserialize(_instance.getStringList(pref.key));
}
