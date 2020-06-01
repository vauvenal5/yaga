import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yaga/model/preference.dart';

class SharedPreferencesService {
  SharedPreferences _instance;

  Future<SharedPreferences> _getOrLoadSharedPreferences() async {
    if(_instance == null) {
      _instance = await SharedPreferences.getInstance();
    }

    return _instance;
  }

  // Future<String> loadStringPreference(Preferences pref) {
  //   print(pref.toString());
  //   return _getOrLoadSharedPreferences().asStream()
  //     .map((prefs) => prefs.getString(pref.toString()) ?? defaults[pref]).first;
  // }

  Stream<String> loadStringPreference(StringPreference pref) {
    print(pref.toString());
    return _getOrLoadSharedPreferences().asStream()
      .map((prefs) => prefs.getString(pref.key) ?? pref.value);
  }

  Stream<bool> saveStringPreference(StringPreference pref) {
    return _getOrLoadSharedPreferences().asStream()
      .flatMap((prefs) => prefs.setString(pref.key, pref.value).asStream());
  }
}