import 'package:flutter/material.dart';
import 'package:rx_command/rx_command.dart';
import 'package:yaga/model/preferences/preference.dart';

class SettingsScreenArguments {
  RxCommand<Preference, dynamic> onSettingChangedCommand;
  List<Preference> preferences;
  void Function() onCommit;
  void Function() onCancel;

  SettingsScreenArguments(
      {@required this.preferences,
      this.onSettingChangedCommand,
      this.onCommit,
      this.onCancel});
}
