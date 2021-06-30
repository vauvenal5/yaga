import 'dart:isolate';

import 'package:yaga/managers/settings_manager_base.dart';
import 'package:yaga/utils/forground_worker/isolateable.dart';
import 'package:yaga/utils/forground_worker/messages/init_msg.dart';

class IsolatedSettingsManager extends SettingsManagerBase
    with Isolateable<IsolatedSettingsManager> {
  @override
  Future<IsolatedSettingsManager> initIsolated(
    InitMsg init,
    SendPort isolateToMain,
  ) async {
    updateSettingCommand(init.mapping);
    return this;
  }
}
