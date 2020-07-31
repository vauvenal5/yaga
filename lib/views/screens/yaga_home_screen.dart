import 'package:flutter/material.dart';
import 'package:yaga/managers/nextcloud_manager.dart';
import 'package:yaga/managers/settings_manager.dart';
import 'package:yaga/model/nc_login_data.dart';
import 'package:yaga/model/preference.dart';
import 'package:yaga/model/route_args/settings_screen_arguments.dart';
import 'package:yaga/services/local_image_provider_service.dart';
import 'package:yaga/services/nextcloud_service.dart';
import 'package:yaga/utils/service_locator.dart';
import 'package:yaga/views/screens/nc_address_screen.dart';
import 'package:yaga/views/screens/settings_screen.dart';
import 'package:yaga/views/widgets/avatar_widget.dart';
import 'package:yaga/views/widgets/browse_tab.dart';
import 'package:yaga/views/widgets/category_tab.dart';

enum YagaHomeTab {grid, folder}

class YagaHomeScreen extends StatefulWidget {
  static const String route = "/";
  
  @override
  State<StatefulWidget> createState() => YagaHomeScreenState();
  
}

class YagaHomeScreenState extends State<YagaHomeScreen> {
  YagaHomeTab _selectedTab;

  
  final List<Preference> _globalAppPreferences = [];

  YagaHomeScreenState() {
    SectionPreference ncSection = SectionPreference("nc", "Nextcloud");
    _globalAppPreferences.add(ncSection);

    //todo: on logged out disable setting instead removing it
    getIt.getAsync<NextCloudManager>().then((ncManager) => ncManager.updateLoginStateCommand.listen((value) {
      getIt.getAsync<NextCloudService>().then((ncService) {
        getIt.getAsync<LocalImageProviderService>().then((localService) {
          getIt.getAsync<SettingsManager>().then((settingsManager) {
            //todo: refactor
            if(ncService.isLoggedIn()) {
              MappingPreference mapping = MappingPreference.section(
                ncSection, 
                "mapping", 
                "Root Mapping",
                active: false,
                local: localService.externalAppDirUri,
                remote: ncService.getRoot()
              );
              _globalAppPreferences.add(mapping);
              settingsManager.loadMappingPreferenceCommand(mapping);
              return;
            }
          
            MappingPreference mapping = MappingPreference.section(
              ncSection, 
              "mapping", 
              "Root Mapping",
              active: false,
              local: localService.externalAppDirUri,
              remote: null
            );

            settingsManager.removeMappingPreferenceCommand(mapping);
            _globalAppPreferences.removeWhere((element) => element.key == mapping.key);
          });
        });
      });
    }));
    getIt.getAsync<NextCloudManager>().then((ncService) => ncService.loadLoginDataCommand());
  }

  int _getCurrentIndex() {
    switch(this._selectedTab) {
      case YagaHomeTab.folder:
        return 1;
      default:
        return 0;
    }
  }

  void _setSelectedTab(YagaHomeTab tab) {
    setState(() {
      _selectedTab = tab;
    });
  }

  @override
  Widget build(BuildContext context) {
    BottomNavigationBar bottomNavBar = BottomNavigationBar(
      currentIndex: _getCurrentIndex(),
      onTap: (index) {
        Navigator.popUntil(context, ModalRoute.withName(YagaHomeScreen.route));

        if(index == _getCurrentIndex()) {
          return;
        }

        switch(index) {
          case 1:
            _setSelectedTab(YagaHomeTab.folder);
            return;
          default:
            _setSelectedTab(YagaHomeTab.grid);
        }
      },
      items: const <BottomNavigationBarItem>[
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          title: Text('Home View'),
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.folder),
          title: Text('Browse View'),
        ),
      ],
    );

    Drawer drawer = Drawer(
      child: ListView(
        children: <Widget>[
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).accentColor,
            ),
            child: StreamBuilder<NextCloudLoginData>(
              stream: getIt.get<NextCloudManager>().updateLoginStateCommand,
              initialData: getIt.get<NextCloudManager>().updateLoginStateCommand.lastResult,
              builder: (context, snapshot) {
                NextCloudService ncService = getIt.get<NextCloudService>();
                return Align(
                  alignment: Alignment.centerLeft,
                  child: ListTile(
                    leading: AvatarWidget.command(getIt.get<NextCloudManager>().updateAvatarCommand, radius: 25,),
                    title: Text(ncService.isLoggedIn()?ncService.username:"", style: TextStyle(color: Colors.white),),
                    subtitle: Text(ncService.isLoggedIn()?ncService.host:"", style: TextStyle(color: Colors.white),),
                  )
                );
              }
            )
          ),
          ListTile(
            leading: Icon(Icons.settings), 
            title: Text("Global Settings"),
            onTap: () => Navigator.pushNamed(context, SettingsScreen.route, arguments: new SettingsScreenArguments(preferences: _globalAppPreferences)),
          ),
          StreamBuilder<NextCloudLoginData>(
            stream: getIt.get<NextCloudManager>().updateLoginStateCommand,
            initialData: getIt.get<NextCloudManager>().updateLoginStateCommand.lastResult,
            builder: (context, snapshot) {
              if(getIt.get<NextCloudService>().isLoggedIn()) {
                return ListTile(
                  leading: Icon(Icons.power_settings_new), 
                  title: Text("Logout"),
                  onTap: () => getIt.get<NextCloudManager>().logoutCommand(),
                );
              }

              return ListTile(
                leading: Icon(Icons.add_to_home_screen), 
                title: Text("Login"),
                onTap: () => Navigator.pushNamed(context, NextCloudAddressScreen.route),
              );
            }
          )
        ],
      )
    );

    return FutureBuilder(
      future: getIt.allReady(),
      builder: (context, snapshot) {
        if(!snapshot.hasData) {
          //todo: at some point replace this simple indicator with a proper flash screen
          return CircularProgressIndicator();
        }

        switch(this._selectedTab) {
          case YagaHomeTab.folder:
            return BrowseTab(bottomNavBar: bottomNavBar, drawer: drawer,);
          default:
            return CategoryTab(bottomNavBar: bottomNavBar, drawer: drawer,);
        }
      }
    );
  }
}