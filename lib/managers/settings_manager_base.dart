import 'package:rx_command/rx_command.dart';
import 'package:yaga/model/preferences/preference.dart';

abstract class SettingsManagerBase {
  late RxCommand<Preference, Preference> updateSettingCommand;

  SettingsManagerBase() {
    updateSettingCommand = RxCommand.createSync((param) => param);
  }
}
