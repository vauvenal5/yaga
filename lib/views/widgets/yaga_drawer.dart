import 'package:flutter/material.dart';
import 'package:package_info/package_info.dart';
import 'package:yaga/managers/global_settings_manager.dart';
import 'package:yaga/managers/nextcloud_manager.dart';
import 'package:yaga/model/nc_login_data.dart';
import 'package:yaga/model/preferences/preference.dart';
import 'package:yaga/model/route_args/settings_screen_arguments.dart';
import 'package:yaga/services/isolateable/nextcloud_service.dart';
import 'package:yaga/utils/service_locator.dart';
import 'package:yaga/views/screens/nc_address_screen.dart';
import 'package:yaga/views/screens/settings_screen.dart';
import 'package:yaga/views/widgets/avatar_widget.dart';

class YagaDrawer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
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
                      ncService.isLoggedIn() ? ncService.origin.username : "",
                      style: TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      ncService.isLoggedIn() ? ncService.origin.domain : "",
                      style: TextStyle(color: Colors.white),
                    ),
                  ));
            },
          ),
        ),
        StreamBuilder<List<Preference>>(
          initialData: getIt
              .get<GlobalSettingsManager>()
              .updateGlobalSettingsCommand
              .lastResult,
          stream:
              getIt.get<GlobalSettingsManager>().updateGlobalSettingsCommand,
          builder: (context, snapshot) => ListTile(
            leading: Icon(Icons.settings),
            title: Text("Global Settings"),
            onTap: () => Navigator.pushNamed(context, SettingsScreen.route,
                arguments:
                    new SettingsScreenArguments(preferences: snapshot.data)),
          ),
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
