import 'package:rxdart/rxdart.dart';
import 'package:rx_command/rx_command.dart';
import 'package:yaga/model/preference.dart';
import 'package:yaga/services/nextcloud_service.dart';
import 'package:yaga/services/shared_preferences_service.dart';

typedef PrefFunction = T Function<T extends ValuePreference>(T);

class SettingsManager {
  SharedPreferencesService _sharedPreferencesService;
  NextCloudService _nextCloudService;

  RxCommand<Preference, Preference> updateSettingCommand;

  RxCommand<StringPreference, void> persistStringSettingCommand;
  RxCommand<BoolPreference, void> persistBoolSettingCommand;
  RxCommand<UriPreference, void> persistUriSettingCommand;
  RxCommand<MappingPreference, MappingPreference> persistMappingPreferenceCommand;

  SettingsManager(this._sharedPreferencesService) {

    updateSettingCommand = RxCommand.createSync((param) => param);

    persistStringSettingCommand = RxCommand.createAsync((param) => _sharedPreferencesService.saveStringPreference(param)
      .then((value) => _checkPersistResult(value, param, _sharedPreferencesService.loadStringPreference))
    );

    persistBoolSettingCommand = RxCommand.createAsync((param) => _sharedPreferencesService.saveBoolPreference(param)
      .then((value) => _checkPersistResult(value, param, _sharedPreferencesService.loadBoolPreference))
    );

    persistUriSettingCommand = RxCommand.createAsync((param) => _sharedPreferencesService.saveUriPreference(param)
      .then((value) => _checkPersistResult(value, param, _sharedPreferencesService.loadUriPreference))
    );

    persistMappingPreferenceCommand = RxCommand.createSync((param) => param);
    persistMappingPreferenceCommand.listen((value) async {
      //todo: add error handling in case one of those fails
      await _sharedPreferencesService.saveComplexPreference(value, overrideValue: false);
      await _sharedPreferencesService.saveUriPreference(value.remote);
      await _sharedPreferencesService.saveUriPreference(value.local);
      _sharedPreferencesService.saveComplexPreference(value)
        .then((res) => _checkPersistResult(res, value, _sharedPreferencesService.loadMappingPreference));
    });
  }

  void _checkPersistResult<T extends Preference>(bool res, T defaultPref, T Function(T) onLoadPref) {
    if(!res) {
      //todo: add error handling if value==false
      //return;
    }
      
    updateSettingCommand(onLoadPref(defaultPref));
  }
}