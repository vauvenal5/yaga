import 'package:rx_command/rx_command.dart';
import 'package:yaga/managers/settings_manager_base.dart';
import 'package:yaga/model/preferences/bool_preference.dart';
import 'package:yaga/model/preferences/choice_preference.dart';
import 'package:yaga/model/preferences/mapping_preference.dart';
import 'package:yaga/model/preferences/preference.dart';
import 'package:yaga/model/preferences/string_preference.dart';
import 'package:yaga/model/preferences/uri_preference.dart';
import 'package:yaga/model/preferences/value_preference.dart';
import 'package:yaga/services/isolateable/nextcloud_service.dart';
import 'package:yaga/services/shared_preferences_service.dart';

typedef PrefFunction = T Function<T extends ValuePreference>(T);

class SettingsManager extends SettingsManagerBase {
  SharedPreferencesService _sharedPreferencesService;
  NextCloudService _nextCloudService;

  RxCommand<StringPreference, void> persistStringSettingCommand;
  RxCommand<BoolPreference, void> persistBoolSettingCommand;
  RxCommand<UriPreference, void> persistUriSettingCommand;
  RxCommand<ChoicePreference, void> persistChoiceSettingCommand;
  RxCommand<MappingPreference, MappingPreference>
      persistMappingPreferenceCommand;
  RxCommand<MappingPreference, MappingPreference>
      removeMappingPreferenceCommand;
  RxCommand<MappingPreference, MappingPreference> loadMappingPreferenceCommand;

  SettingsManager(this._sharedPreferencesService) {
    persistStringSettingCommand = RxCommand.createAsync((param) =>
        _sharedPreferencesService.savePreferenceToString(param).then((value) =>
            _checkPersistResult(value, param,
                _sharedPreferencesService.loadPreferenceFromString)));

    persistBoolSettingCommand = RxCommand.createAsync((param) =>
        _sharedPreferencesService.savePreferenceToBool(param).then((value) =>
            _checkPersistResult(value, param,
                _sharedPreferencesService.loadPreferenceFromBool)));

    persistUriSettingCommand = RxCommand.createAsync((param) =>
        _sharedPreferencesService.savePreferenceToString(param).then((value) =>
            _checkPersistResult(value, param,
                _sharedPreferencesService.loadPreferenceFromString)));

    persistChoiceSettingCommand = RxCommand.createAsync((param) =>
        _sharedPreferencesService.savePreferenceToString(param).then((value) =>
            _checkPersistResult(value, param,
                _sharedPreferencesService.loadPreferenceFromString)));

    persistMappingPreferenceCommand = RxCommand.createSync((param) => param);
    persistMappingPreferenceCommand.listen((value) async {
      //todo: add error handling in case one of those fails
      // await _sharedPreferencesService.saveComplexPreference(value,
      //     overrideValue: false);
      await _sharedPreferencesService.savePreferenceToBool(value);
      await _sharedPreferencesService.savePreferenceToString(value.remote);
      await _sharedPreferencesService.savePreferenceToString(value.local);
      // _sharedPreferencesService.saveComplexPreference(value).then((res) =>
      _sharedPreferencesService.savePreferenceToBool(value).then((res) =>
          _checkPersistResult(
              res, value, _sharedPreferencesService.loadPreferenceFromBool));
    });

    removeMappingPreferenceCommand = RxCommand.createSync((param) => param);
    removeMappingPreferenceCommand.listen((value) async {
      await _sharedPreferencesService.removePreference(value.local);
      await _sharedPreferencesService.removePreference(value.remote);
      await _sharedPreferencesService.removePreference(value);
    });

    loadMappingPreferenceCommand = RxCommand.createSync((param) => param);
    loadMappingPreferenceCommand.listen((value) {
      UriPreference remote =
          _sharedPreferencesService.loadPreferenceFromString(value.remote);
      UriPreference local =
          _sharedPreferencesService.loadPreferenceFromString(value.local);
      updateSettingCommand(_sharedPreferencesService.loadPreferenceFromBool(
        value.rebuild((b) => b
          ..remote = remote.toBuilder()
          ..local = local.toBuilder()),
      ));
    });
  }

  void _checkPersistResult<T extends Preference>(
      bool res, T defaultPref, T Function(T) onLoadPref) {
    if (!res) {
      //todo: add error handling if value==false
      //return;
    }

    updateSettingCommand(onLoadPref(defaultPref));
  }
}
