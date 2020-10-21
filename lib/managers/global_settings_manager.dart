import 'package:flutter/foundation.dart';
import 'package:rx_command/rx_command.dart';
import 'package:yaga/managers/nextcloud_manager.dart';
import 'package:yaga/managers/settings_manager.dart';
import 'package:yaga/model/nc_login_data.dart';
import 'package:yaga/model/preference.dart';
import 'package:yaga/services/isolateable/nextcloud_service.dart';
import 'package:yaga/services/isolateable/system_location_service.dart';
import 'package:yaga/utils/uri_utils.dart';

class GlobalSettingsManager {
  List<Preference> _globalSettingsCache = [];
  static SectionPreference ncSection = SectionPreference("nc", "Nextcloud");
  static SectionPreference appSection = SectionPreference("app", "General");
  static ChoicePreference theme = ChoicePreference.section(
      appSection, "theme", "Theme", "system", {
    "system": "Follow System Theme",
    "light": "Light Theme",
    "dark": "Dark Theme"
  });

  RxCommand<Preference, Preference> registerGlobalSettingCommand =
      RxCommand.createSync((param) => param);
  RxCommand<Preference, void> removeGlobalSettingCommand;
  RxCommand<List<Preference>, List<Preference>> updateGlobalSettingsCommand =
      RxCommand.createSync((param) => param);

  RxCommand<MappingPreference, MappingPreference> updateRootMappingPreference =
      RxCommand.createSync((param) => param);

  NextCloudManager _nextcloudManager;
  SettingsManager _settingsManager;

  NextCloudService _nextCloudService;
  SystemLocationService _systemLocationService;

  GlobalSettingsManager(this._nextcloudManager, this._settingsManager,
      this._nextCloudService, this._systemLocationService) {
    registerGlobalSettingCommand.listen((pref) {
      if (_globalSettingsCache.contains(pref)) {
        return;
      }
      this._globalSettingsCache.add(pref);
      this.updateGlobalSettingsCommand(this._globalSettingsCache);
    });
    removeGlobalSettingCommand = RxCommand.createSync((param) =>
        _globalSettingsCache
            .removeWhere((element) => element.key == param.key));
    removeGlobalSettingCommand.listen((value) {
      this.updateGlobalSettingsCommand(this._globalSettingsCache);
    });

    this
        ._nextcloudManager
        .updateLoginStateCommand
        .listen((value) => _handleLoginState(value));

    this._nextcloudManager.logoutCommand.listen((value) {
      MappingPreference mapping = this.getDefaultMappingPreference(
          local: _systemLocationService.externalAppDirUri);

      _settingsManager.removeMappingPreferenceCommand(mapping);
      this.removeGlobalSettingCommand(mapping);
      this.removeGlobalSettingCommand(ncSection);
    });

    this
        ._settingsManager
        .updateSettingCommand
        .where((event) =>
            event.key == getDefaultMappingPreference(local: null).key)
        .listen((event) => updateRootMappingPreference(event));
  }

  Future<GlobalSettingsManager> init() async {
    this.registerGlobalSettingCommand(appSection);
    this.registerGlobalSettingCommand(theme);

    _handleLoginState(
        this._nextcloudManager.updateLoginStateCommand.lastResult);

    return this;
  }

  MappingPreference getDefaultMappingPreference(
      {@required Uri local, Uri remote}) {
    return MappingPreference.section(
      ncSection,
      "mapping",
      "Root Mapping",
      active: false,
      local: local,
      remote: remote,
    );
  }

  void _handleLoginState(NextCloudLoginData loginData) {
    if (this._nextCloudService.isLoggedIn()) {
      MappingPreference mapping = this.getDefaultMappingPreference(
        local: UriUtils.fromUri(
            uri: _systemLocationService.externalAppDirUri,
            path:
                "${_systemLocationService.externalAppDirUri.path}/${_nextCloudService.getUserDomain()}"),
        remote: _nextCloudService.getOrigin(),
      );

      this.registerGlobalSettingCommand(ncSection);
      this.registerGlobalSettingCommand(mapping);

      _settingsManager.loadMappingPreferenceCommand(mapping);
    }
  }
}
