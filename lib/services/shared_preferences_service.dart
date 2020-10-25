import 'package:shared_preferences/shared_preferences.dart';
import 'package:yaga/model/preferences/preference.dart';
import 'package:yaga/model/preferences/serializers/preference_serializer.dart';
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
          PreferenceSerializer<String, dynamic, dynamic> pref) =>
      _instance.setString(pref.key, pref.serialize());

  P loadPreferenceFromString<
          P extends PreferenceSerializer<String, dynamic, dynamic>>(P pref) =>
      pref.deserialize(this._instance.getString(pref.key));

  Future<bool> savePreferenceToBool(
          PreferenceSerializer<bool, dynamic, dynamic> pref) =>
      _instance.setBool(pref.key, pref.serialize());

  P loadPreferenceFromBool<
          P extends PreferenceSerializer<bool, dynamic, dynamic>>(P pref) =>
      pref.deserialize(this._instance.getBool(pref.key));

  Future<bool> savePreferenceToStringList(
          PreferenceSerializer<List<String>, dynamic, dynamic> pref) =>
      _instance.setStringList(pref.key, pref.serialize());

  P loadPreferenceFromStringList<
              P extends PreferenceSerializer<List<String>, dynamic, dynamic>>(
          P pref) =>
      pref.deserialize(this._instance.getStringList(pref.key));
}
