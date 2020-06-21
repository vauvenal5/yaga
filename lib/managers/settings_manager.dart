import 'package:rxdart/rxdart.dart';
import 'package:rx_command/rx_command.dart';
import 'package:yaga/model/preference.dart';
import 'package:yaga/services/local_image_provider_service.dart';
// import 'package:yaga/utils/service_locator.dart';
import 'package:yaga/services/shared_preferences_service.dart';

class SettingsManager {
  SharedPreferencesService _sharedPreferencesService;
  LocalImageProviderService _localImageProviderService;
  // RxCommand<Preferences, String> loadSettingCommand;

  // RxCommand<void, String> loadSourceSettingCommand;
  // RxCommand<String, String> updateSourceSettingCommand;

  RxCommand<Preference, Preference> newLoadSettingCommand;
  RxCommand<Preference, Preference> updateSettingCommand;

  // RxCommand<StringPreference, StringPreference> loadDefaultPath;

  // RxCommand<ValuePreference, ValuePreference> loadSettingCommand;

  SettingsManager(this._sharedPreferencesService, this._localImageProviderService) {
    //loadSettingCommand = RxCommand.createSync((Preferences pref) => pref);
    // loadSettingCommand = RxCommand.createFromStream((Preferences pref) => getIt.get<SharedPreferencesService>().loadStringPreference(pref));
    // loadSettingCommand.listen((value) { })

    // loadSourceSettingCommand = RxCommand.createAsyncNoParam(
    //   () => getIt.get<SharedPreferencesService>().loadStringPreference(Preferences.source),
    //   canExecute: loadSettingCommand.map((event) => event == Preferences.source)
    // );
    // updateSourceSettingCommand = RxCommand.createSync((param) => param);

    // loadDefaultPath = RxCommand.createSync((param) => param);
    // loadDefaultPath.listen((value) async {
    //   value.value = (await _localImageProviderService.getExternalAppDirUri()).toString();
    //   newLoadSettingCommand(value);
    // });

    newLoadSettingCommand = RxCommand.createSync((param) => _sharedPreferencesService.loadStringPreference(param));
    //todo: refactor settings handling
    updateSettingCommand = RxCommand.createSync((param) => param);
    updateSettingCommand
      .where((event) => event is StringPreference)
      .flatMap((value) => _sharedPreferencesService.saveStringPreference(value as StringPreference).asStream().map((event) => value))
      .listen((event) => newLoadSettingCommand(event));

    // loadSettingCommand = RxCommand.createSync((param) => param);
    // loadSettingCommand.flatMap((value) => Rx.merge([
    //   Stream.value(value)
    //     .where((event) => event is StringListPreference)
    //     .map((event) => event as StringListPreference)
    //     .map((value) => _sharedPreferencesService.loadStringListPreference(value))
    // ]));
  }
}