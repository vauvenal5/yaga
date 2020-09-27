import 'package:logger/logger.dart';
import 'package:rxdart/rxdart.dart';
import 'package:yaga/managers/settings_manager.dart';
import 'package:yaga/model/preference.dart';
import 'package:yaga/utils/forground_worker/foreground_worker.dart';
import 'package:yaga/utils/forground_worker/messages/preference_msg.dart';
import 'package:yaga/utils/logger.dart';

class SettingsManagerBridge {
  Logger _logger = getLogger(SettingsManagerBridge);
  final SettingsManager _settingsManager;
  final ForegroundWorker _worker;

  SettingsManagerBridge(this._settingsManager, this._worker);

  Future<SettingsManagerBridge> init() async {
    _settingsManager.updateSettingCommand
      .doOnData((event) {
        _logger.w(event);
      })
      .where((event) => event is MappingPreference)
      .listen((event) => _worker.sendRequest(PreferenceMsg("", event)));

    //todo-important: this works by luck(!) we need to solve this properly!
    // it works only because in the yagahomescreen mappingPref is the last one loaded
    this._worker.sendRequest(PreferenceMsg("", _settingsManager.updateSettingCommand.lastResult));
    return this;
  }
}