import 'package:rx_command/rx_command.dart';
import 'package:yaga/managers/settings_manager_base.dart';
import 'package:yaga/model/preference.dart';
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
        _sharedPreferencesService.saveStringPreference(param).then((value) =>
            _checkPersistResult(
                value, param, _sharedPreferencesService.loadStringPreference)));

    persistBoolSettingCommand = RxCommand.createAsync((param) =>
        _sharedPreferencesService.saveBoolPreference(param).then((value) =>
            _checkPersistResult(
                value, param, _sharedPreferencesService.loadBoolPreference)));

    persistUriSettingCommand = RxCommand.createAsync((param) =>
        _sharedPreferencesService.saveUriPreference(param).then((value) =>
            _checkPersistResult(
                value, param, _sharedPreferencesService.loadUriPreference)));

    persistChoiceSettingCommand = RxCommand.createAsync((param) =>
        _sharedPreferencesService.saveChoicePreference(param).then((value) =>
            _checkPersistResult(
                value, param, _sharedPreferencesService.loadChoicePreference)));

    persistMappingPreferenceCommand = RxCommand.createSync((param) => param);
    persistMappingPreferenceCommand.listen((value) async {
      //todo: add error handling in case one of those fails
      await _sharedPreferencesService.saveComplexPreference(value,
          overrideValue: false);
      await _sharedPreferencesService.saveUriPreference(value.remote);
      await _sharedPreferencesService.saveUriPreference(value.local);
      _sharedPreferencesService.saveComplexPreference(value).then((res) =>
          _checkPersistResult(
              res, value, _sharedPreferencesService.loadMappingPreference));
    });

    removeMappingPreferenceCommand = RxCommand.createSync((param) => param);
    removeMappingPreferenceCommand.listen((value) async {
      await _sharedPreferencesService.removePreference(value.local);
      await _sharedPreferencesService.removePreference(value.remote);
      await _sharedPreferencesService.removePreference(value);
    });

    loadMappingPreferenceCommand = RxCommand.createSync((param) => param);
    loadMappingPreferenceCommand.listen((value) {
      value.remote = _sharedPreferencesService.loadUriPreference(value.remote);
      value.local = _sharedPreferencesService.loadUriPreference(value.local);
      updateSettingCommand(
          _sharedPreferencesService.loadMappingPreference(value));
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
