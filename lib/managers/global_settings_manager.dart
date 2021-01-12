import 'package:flutter/foundation.dart';
import 'package:rx_command/rx_command.dart';
import 'package:yaga/managers/nextcloud_manager.dart';
import 'package:yaga/managers/settings_manager.dart';
import 'package:yaga/model/nc_login_data.dart';
import 'package:yaga/model/preferences/mapping_preference.dart';
import 'package:yaga/model/preferences/preference.dart';
import 'package:yaga/model/preferences/choice_preference.dart';
import 'package:yaga/model/preferences/section_preference.dart';
import 'package:yaga/services/isolateable/nextcloud_service.dart';
import 'package:yaga/services/isolateable/system_location_service.dart';
import 'package:yaga/utils/uri_utils.dart';

class GlobalSettingsManager {
  List<Preference> _globalSettingsCache = [];
  static const String _MAPPING_KEY = "mapping";
  static SectionPreference ncSection = SectionPreference((b) => b
    ..key = "nc"
    ..title = "Nextcloud");
  static SectionPreference appSection = SectionPreference((b) => b
    ..key = "app"
    ..title = "General");
  static ChoicePreference theme = ChoicePreference((b) => b
    ..key = appSection.prepareKey("theme")
    ..title = "Theme"
    ..value = "system"
    ..choices = {
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
        local: _systemLocationService.externalAppDirUri,
        remote: Uri(),
      );

      _settingsManager.removeMappingPreferenceCommand(mapping);
      this.removeGlobalSettingCommand(mapping);
      this.removeGlobalSettingCommand(ncSection);
    });

    this
        ._settingsManager
        .updateSettingCommand
        .where((event) => event.key == ncSection.prepareKey(_MAPPING_KEY))
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
    return MappingPreference((b) => b
      ..key = ncSection.prepareKey(_MAPPING_KEY)
      ..title = "Root Mapping"
      ..value = false
      ..local.value = local
      ..remote.value = remote);
  }

  void _handleLoginState(NextCloudLoginData loginData) {
    if (this._nextCloudService.isLoggedIn()) {
      MappingPreference mapping = this.getDefaultMappingPreference(
        local: UriUtils.fromUri(
          uri: _systemLocationService.externalAppDirUri,
          path:
              "${_systemLocationService.externalAppDirUri.path}/${_nextCloudService.origin.userDomain}",
        ),
        remote: _nextCloudService.origin.userEncodedDomainRoot,
      );

      this.registerGlobalSettingCommand(ncSection);
      this.registerGlobalSettingCommand(mapping);

      _settingsManager.loadMappingPreferenceCommand(mapping);
    }
  }
}
