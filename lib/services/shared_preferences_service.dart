import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yaga/model/preference.dart';
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

  StringListPreference loadStringListPreference(StringListPreference pref) 
    => StringListPreference(pref.key, pref.title, _instance.getStringList(pref.key)??pref.value);

  Future<bool> saveStringListPreference(StringListPreference pref) => _instance.setStringList(pref.key, pref.value);

  StringPreference loadStringPreference(StringPreference pref) => 
    StringPreference(pref.key, pref.title, _instance.getString(pref.key) ?? pref.value);
  
  BoolPreference loadBoolPreference(BoolPreference pref) => 
    BoolPreference(pref.key, pref.title, _instance.getBool(pref.key) ?? pref.value);
  
  ChoicePreference loadChoicePreference(ChoicePreference pref) => 
    ChoicePreference(pref.key, pref.title, _instance.getString(pref.key) ?? pref.value, pref.choices);

  Future<bool> saveChoicePreference(ChoicePreference pref) => _instance.setString(pref.key, pref.value);
  
  Future<bool> saveStringPreference(StringPreference pref) => _instance.setString(pref.key, pref.value);

  Future<bool> saveBoolPreference(BoolPreference pref) => _instance.setBool(pref.key, pref.value);

  UriPreference loadUriPreference(UriPreference pref) {
    String value = _instance.getString(pref.key);
    Uri uri = value != null ? Uri.parse(value) : pref.value;
    return UriPreference(pref.key, pref.title, uri);
  }

  Future<bool> saveUriPreference(UriPreference pref) => _instance.setString(pref.key, pref.value.toString());

  Future<bool> saveComplexPreference(ComplexPreference pref, {bool overrideValue}) => _instance.setBool(pref.key, overrideValue??pref.value);

  MappingPreference loadMappingPreference(MappingPreference pref) => 
    MappingPreference(pref.key, pref.title, pref.remote, pref.local, active: _instance.getBool(pref.key));

  Future<bool> removePreference(Preference pref) => _instance.remove(pref.key);
}