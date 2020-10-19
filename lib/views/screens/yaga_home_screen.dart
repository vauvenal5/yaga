import 'package:flutter/material.dart';
import 'package:package_info/package_info.dart';
import 'package:yaga/main.dart';
import 'package:yaga/managers/nextcloud_manager.dart';
import 'package:yaga/managers/settings_manager.dart';
import 'package:yaga/managers/tab_manager.dart';
import 'package:yaga/model/nc_login_data.dart';
import 'package:yaga/model/preference.dart';
import 'package:yaga/model/route_args/settings_screen_arguments.dart';
import 'package:yaga/services/isolateable/nextcloud_service.dart';
import 'package:yaga/services/isolateable/system_location_service.dart';
import 'package:yaga/utils/service_locator.dart';
import 'package:yaga/utils/uri_utils.dart';
import 'package:yaga/views/screens/nc_address_screen.dart';
import 'package:yaga/views/screens/settings_screen.dart';
import 'package:yaga/views/screens/splash_screen.dart';
import 'package:yaga/views/widgets/avatar_widget.dart';
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

    _globalAppPreferences.add(MyApp.appSection);
    _globalAppPreferences.add(MyApp.theme);

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

        _globalAppPreferences.add(ncSection);
        _globalAppPreferences.add(mapping);

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
      _globalAppPreferences
          .removeWhere((element) => element.key == mapping.key);
      _globalAppPreferences
          .removeWhere((element) => element.key == ncSection.key);
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

        Drawer drawer = _getDrawer();

        return StreamBuilder<YagaHomeTab>(
          initialData: YagaHomeTab.grid,
          stream: getIt.get<TabManager>().tabChangedCommand,
          builder: (context, snapshot) {
            return IndexedStack(
              index: this._getCurrentIndex(snapshot.data),
              children: <Widget>[
                CategoryTab(
                  drawer: drawer,
                ),
                BrowseTab(
                  drawer: drawer,
                )
              ],
            );
          },
        );
      },
    );
  }

  Drawer _getDrawer() {
    return Drawer(
        child: ListView(
      children: <Widget>[
        DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).accentColor,
            ),
            child: StreamBuilder<NextCloudLoginData>(
                stream: getIt.get<NextCloudManager>().updateLoginStateCommand,
                initialData: getIt
                    .get<NextCloudManager>()
                    .updateLoginStateCommand
                    .lastResult,
                builder: (context, snapshot) {
                  NextCloudService ncService = getIt.get<NextCloudService>();
                  return Align(
                      alignment: Alignment.centerLeft,
                      child: ListTile(
                        leading: AvatarWidget.command(
                          getIt.get<NextCloudManager>().updateAvatarCommand,
                          radius: 25,
                        ),
                        title: Text(
                          ncService.isLoggedIn() ? ncService.username : "",
                          style: TextStyle(color: Colors.white),
                        ),
                        subtitle: Text(
                          ncService.isLoggedIn() ? ncService.host : "",
                          style: TextStyle(color: Colors.white),
                        ),
                      ));
                })),
        ListTile(
          leading: Icon(Icons.settings),
          title: Text("Global Settings"),
          onTap: () => Navigator.pushNamed(context, SettingsScreen.route,
              arguments: new SettingsScreenArguments(
                  preferences: _globalAppPreferences)),
        ),
        StreamBuilder<NextCloudLoginData>(
            stream: getIt.get<NextCloudManager>().updateLoginStateCommand,
            initialData: getIt
                .get<NextCloudManager>()
                .updateLoginStateCommand
                .lastResult,
            builder: (context, snapshot) {
              if (getIt.get<NextCloudService>().isLoggedIn()) {
                return ListTile(
                  leading: Icon(Icons.power_settings_new),
                  title: Text("Logout"),
                  onTap: () => getIt.get<NextCloudManager>().logoutCommand(),
                );
              }

              return ListTile(
                leading: Icon(Icons.add_to_home_screen),
                title: Text("Login"),
                onTap: () =>
                    Navigator.pushNamed(context, NextCloudAddressScreen.route),
              );
            }),
        //todo: improve this (fill text and move to bottom)
        AboutListTile(
          icon: Icon(Icons.info_outline),
          applicationVersion: "v" + getIt.get<PackageInfo>().version,
          applicationIcon: Image.asset(
            'assets/icon/ic_launcher_xxxhdpi.png',
            width: 56,
          ),
        )
      ],
    ));
  }
}
