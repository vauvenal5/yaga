import 'package:shared_preferences/shared_preferences.dart';
import 'package:yaga/model/preferences/bool_preference.dart';
import 'package:yaga/model/preferences/choice_preference.dart';
import 'package:yaga/model/preferences/complex_preference.dart';
import 'package:yaga/model/preferences/mapping_preference.dart';
import 'package:yaga/model/preferences/preference.dart';
import 'package:yaga/model/preferences/string_list_preference.dart';
import 'package:yaga/model/preferences/string_preference.dart';
import 'package:yaga/model/preferences/uri_preference.dart';
import 'package:yaga/model/preferences/value_preference.dart';
import 'package:yaga/services/service.dart';

class SharedPreferencesService extends Service<SharedPreferencesService> {
  SharedPreferences _instance;

  @override
  Future<SharedPreferencesService> init() async {
    _instance = await SharedPreferences.getInstance();
    return this;
  }

  // Future<String> loadStringPreference(Preferences pref) {
  //   print(pref.toString());
  //   return _getOrLoadSharedPreferences().asStream()
  //     .map((prefs) => prefs.getString(pref.toString()) ?? defaults[pref]).first;
  // }

  StringListPreference loadStringListPreference(StringListPreference pref) =>
      pref.rebuild(
          (b) => b..value = _instance.getStringList(pref.key) ?? pref.value);

  Future<bool> saveStringListPreference(StringListPreference pref) =>
      _instance.setStringList(pref.key, pref.value);

  StringPreference loadStringPreference(StringPreference pref) => pref
      .rebuild((b) => b..value = _instance.getString(pref.key) ?? pref.value);

  BoolPreference loadBoolPreference(BoolPreference pref) =>
      pref.rebuild((b) => b.value = _instance.getBool(pref.key) ?? pref.value);

  ChoicePreference loadChoicePreference(ChoicePreference pref) => pref
      .rebuild((b) => b.value = _instance.getString(pref.key) ?? pref.value);

  Future<bool> saveChoicePreference(ChoicePreference pref) =>
      _instance.setString(pref.key, pref.value);

  Future<bool> saveStringPreference(StringPreference pref) =>
      _instance.setString(pref.key, pref.value);

  Future<bool> saveBoolPreference(BoolPreference pref) =>
      _instance.setBool(pref.key, pref.value);

  UriPreference loadUriPreference(UriPreference pref) {
    String value = _instance.getString(pref.key);
    Uri uri = value != null ? Uri.parse(value) : pref.value;
    return pref.rebuild((b) => b..value = uri);
  }

  Future<bool> saveUriPreference(UriPreference pref) =>
      _instance.setString(pref.key, pref.value.toString());

  Future<bool> saveComplexPreference(ComplexPreference pref,
          {bool overrideValue}) =>
      _instance.setBool(pref.key, overrideValue ?? pref.value);

  MappingPreference loadMappingPreference(MappingPreference pref) =>
      pref.rebuild((b) => b..value = _instance.getBool(pref.key));

  Future<bool> removePreference(Preference pref) => _instance.remove(pref.key);
}
