import 'package:flutter/material.dart';
import 'package:yaga/managers/nextcloud_manager.dart';
import 'package:yaga/managers/settings_manager.dart';
import 'package:yaga/managers/tab_manager.dart';
import 'package:yaga/model/preference.dart';
import 'package:yaga/services/isolateable/nextcloud_service.dart';
import 'package:yaga/services/isolateable/system_location_service.dart';
import 'package:yaga/utils/service_locator.dart';
import 'package:yaga/utils/uri_utils.dart';
import 'package:yaga/views/screens/splash_screen.dart';
import 'package:yaga/views/widgets/browse_tab.dart';
import 'package:yaga/views/widgets/category_tab.dart';

enum YagaHomeTab { grid, folder }

class YagaHomeScreen extends StatefulWidget {
  static const String route = "/";

  @override
  State<StatefulWidget> createState() => YagaHomeScreenState();
}

//todo: yagaHomeScreen can probably be transoformed into a stateless widget
class YagaHomeScreenState extends State<YagaHomeScreen> {
  final List<Preference> _globalAppPreferences = [];
  final nextcloudManger = getIt.get<NextCloudManager>();

  void initState() {
    super.initState();

    SectionPreference ncSection = SectionPreference("nc", "Nextcloud");

    //todo: on logged out disable setting instead removing it
    var nextcloudService = getIt.get<NextCloudService>();
    var systemLocationService = getIt.get<SystemLocationService>();
    var settingsManager = getIt.get<SettingsManager>();

    nextcloudManger.updateLoginStateCommand.listen((value) {
      if (nextcloudService.isLoggedIn()) {
        MappingPreference mapping = MappingPreference.section(
            ncSection, "mapping", "Root Mapping",
            active: false,
            //todo: this should be moved in some form to the mapping manger... maybe when enabling multi user
            local: UriUtils.fromUri(
                uri: systemLocationService.externalAppDirUri,
                path:
                    "${systemLocationService.externalAppDirUri.path}/${nextcloudService.getUserDomain()}"),
            remote: nextcloudService.getOrigin());

        settingsManager.registerGlobalSettingCommand(ncSection);
        settingsManager.registerGlobalSettingCommand(mapping);

        settingsManager.loadMappingPreferenceCommand(mapping);
      }
    });

    nextcloudManger.logoutCommand.listen((value) {
      MappingPreference mapping = MappingPreference.section(
          ncSection, "mapping", "Root Mapping",
          active: false,
          local: systemLocationService.externalAppDirUri,
          remote: null);

      settingsManager.removeMappingPreferenceCommand(mapping);
      settingsManager.removeGlobalSettingCommand(mapping);
      settingsManager.removeGlobalSettingCommand(ncSection);
    });
  }

  int _getCurrentIndex(YagaHomeTab tab) {
    switch (tab) {
      case YagaHomeTab.folder:
        return 1;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      initialData: true,
      stream: nextcloudManger.loadLoginDataCommand.isExecuting,
      builder: (context, snapshot) {
        if (snapshot.data) {
          nextcloudManger.loadLoginDataCommand();
          return SplashScreen();
        }

        return StreamBuilder<YagaHomeTab>(
          initialData: YagaHomeTab.grid,
          stream: getIt.get<TabManager>().tabChangedCommand,
          builder: (context, snapshot) {
            return IndexedStack(
              index: this._getCurrentIndex(snapshot.data),
              children: <Widget>[CategoryTab(), BrowseTab()],
            );
          },
        );
      },
    );
  }
}
