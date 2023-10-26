import 'package:rx_command/rx_command.dart';
import 'package:yaga/managers/settings_manager_base.dart';
import 'package:yaga/model/preferences/bool_preference.dart';
import 'package:yaga/model/preferences/int_preference.dart';
import 'package:yaga/model/preferences/mapping_preference.dart';
import 'package:yaga/model/preferences/preference.dart';
import 'package:yaga/model/preferences/serializable_preference.dart';
import 'package:yaga/model/preferences/uri_preference.dart';
import 'package:yaga/model/preferences/value_preference.dart';
import 'package:yaga/services/shared_preferences_service.dart';

typedef PrefFunction = T Function<T extends ValuePreference>(T);

class SettingsManager extends SettingsManagerBase {
  final SharedPreferencesService _sharedPreferencesService;

  late RxCommand<SerializablePreference<String, dynamic, dynamic>, void>
      persistStringSettingCommand;
  late RxCommand<BoolPreference, void> persistBoolSettingCommand;
  late RxCommand<MappingPreference, MappingPreference>
      persistMappingPreferenceCommand;
  late RxCommand<MappingPreference, MappingPreference>
      removeMappingPreferenceCommand;
  late RxCommand<MappingPreference, MappingPreference>
      loadMappingPreferenceCommand;
  late RxCommand<IntPreference, void> persistIntSettingCommand;

  SettingsManager(this._sharedPreferencesService) {
    persistStringSettingCommand = RxCommand.createAsync((param) =>
        _sharedPreferencesService.savePreferenceToString(param).then((value) =>
            _checkPersistResult(value, param,
                _sharedPreferencesService.loadPreferenceFromString)));

    persistBoolSettingCommand = RxCommand.createAsync((param) =>
        _sharedPreferencesService.savePreferenceToBool(param).then((value) =>
            _checkPersistResult(value, param,
                _sharedPreferencesService.loadPreferenceFromBool)));

    persistIntSettingCommand = RxCommand.createAsync(
      (param) => _sharedPreferencesService.savePreferenceToInt(param).then(
            (value) => _checkPersistResult(
              value,
              param,
              _sharedPreferencesService.loadPreferenceFromInt,
            ),
          ),
    );

    persistMappingPreferenceCommand = RxCommand.createSync((param) => param);
    persistMappingPreferenceCommand.listen((value) async {
      //todo: add error handling in case one of those fails
      // await _sharedPreferencesService.saveComplexPreference(value,
      //     overrideValue: false);
      await _sharedPreferencesService.savePreferenceToBool(value);
      await _sharedPreferencesService.savePreferenceToString(value.remote);
      await _sharedPreferencesService.savePreferenceToString(value.local);
      await _sharedPreferencesService.savePreferenceToBool(value.syncDeletes);
      // _sharedPreferencesService.saveComplexPreference(value).then((res) =>
      _sharedPreferencesService.savePreferenceToBool(value).then((res) =>
          _checkPersistResult(
              res, value, _sharedPreferencesService.loadPreferenceFromBool));
    });

    removeMappingPreferenceCommand = RxCommand.createSync((param) => param);
    removeMappingPreferenceCommand.listen((value) async {
      await _sharedPreferencesService.removePreference(value.local);
      await _sharedPreferencesService.removePreference(value.remote);
      await _sharedPreferencesService.removePreference(value.syncDeletes);
      await _sharedPreferencesService.removePreference(value);
    });

    loadMappingPreferenceCommand = RxCommand.createSync((param) => param);
    loadMappingPreferenceCommand.listen((value) {
      final UriPreference remote =
          _sharedPreferencesService.loadPreferenceFromString(value.remote);
      final UriPreference local =
          _sharedPreferencesService.loadPreferenceFromString(value.local);
      final BoolPreference syncDeletes =
          _sharedPreferencesService.loadPreferenceFromBool(value.syncDeletes);
      updateSettingCommand(_sharedPreferencesService.loadPreferenceFromBool(
        value.rebuild(
          (b) => b
            ..remote = remote.toBuilder()
            ..local = local.toBuilder()
            ..syncDeletes = syncDeletes.toBuilder(),
        ),
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
