import 'dart:isolate';

import 'package:yaga/managers/settings_manager_base.dart';
import 'package:yaga/utils/forground_worker/isolateable.dart';
import 'package:yaga/utils/forground_worker/messages/init_msg.dart';

class IsolatedSettingsManager extends SettingsManagerBase
    with Isolateable<IsolatedSettingsManager> {
  Future<IsolatedSettingsManager> initIsolated(
    InitMsg init,
    SendPort isolateToMain,
  ) async {
    this.updateSettingCommand(init.mapping);
    return this;
  }
}
