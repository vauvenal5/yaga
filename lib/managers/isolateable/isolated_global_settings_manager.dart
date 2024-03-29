import 'dart:isolate';

import 'package:yaga/managers/global_settings_manager.dart';
import 'package:yaga/managers/isolateable/isolated_settings_manager.dart';
import 'package:yaga/model/preferences/bool_preference.dart';
import 'package:yaga/utils/forground_worker/isolateable.dart';
import 'package:yaga/utils/forground_worker/messages/init_msg.dart';

class IsolatedGlobalSettingsManager
    with Isolateable<IsolatedGlobalSettingsManager> {
  @override
  Future<IsolatedGlobalSettingsManager> initIsolated(
    InitMsg init,
    SendPort isolateToMain,
  ) async {
    _autoPersist = init.autoPersist;
    return this;
  }

  final IsolatedSettingsManager _settingsManager;

  late BoolPreference _autoPersist;
  BoolPreference get autoPersist => _autoPersist;

  IsolatedGlobalSettingsManager(this._settingsManager) {
    _settingsManager.updateSettingCommand
        .where((event) => event.key == GlobalSettingsManager.autoPersist.key)
        .map((event) => event as BoolPreference)
        .listen((value) => _autoPersist = value);
  }
}
