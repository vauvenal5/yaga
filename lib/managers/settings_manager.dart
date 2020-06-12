import 'package:rxdart/rxdart.dart';
import 'package:rx_command/rx_command.dart';
import 'package:yaga/model/preference.dart';
import 'package:yaga/services/local_image_provider_service.dart';
import 'package:yaga/utils/service_locator.dart';
import 'package:yaga/services/shared_preferences_service.dart';

class SettingsManager {
  // RxCommand<Preferences, String> loadSettingCommand;

  // RxCommand<void, String> loadSourceSettingCommand;
  // RxCommand<String, String> updateSourceSettingCommand;

  RxCommand<Preference, Preference> newLoadSettingCommand;
  RxCommand<Preference, Preference> updateSettingCommand;

  RxCommand<StringPreference, StringPreference> loadDefaultPath;

  SettingsManager() {
    //loadSettingCommand = RxCommand.createSync((Preferences pref) => pref);
    // loadSettingCommand = RxCommand.createFromStream((Preferences pref) => getIt.get<SharedPreferencesService>().loadStringPreference(pref));
    // loadSettingCommand.listen((value) { })

    // loadSourceSettingCommand = RxCommand.createAsyncNoParam(
    //   () => getIt.get<SharedPreferencesService>().loadStringPreference(Preferences.source),
    //   canExecute: loadSettingCommand.map((event) => event == Preferences.source)
    // );
    // updateSourceSettingCommand = RxCommand.createSync((param) => param);

    loadDefaultPath = RxCommand.createSync((param) => param);
    loadDefaultPath.listen((value) async {
      await getIt.get<LocalImageProviderService>().init();
      value.value = (await getIt.get<LocalImageProviderService>().getExternalAppDirUri()).toString();
      newLoadSettingCommand(value);
    });

    newLoadSettingCommand = RxCommand.createFromStream((param) => getIt.get<SharedPreferencesService>().loadStringPreference(param)
      .map((event) => StringPreference(param.key, param.title, event)));

    updateSettingCommand = RxCommand.createSync((param) => param);
    updateSettingCommand
      .where((event) => event is StringPreference)
      .flatMap((value) => getIt.get<SharedPreferencesService>().saveStringPreference(value as StringPreference).map((event) => value))
      .listen((event) => newLoadSettingCommand(event));
  }
}