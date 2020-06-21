import 'package:flutter/material.dart';
import 'package:yaga/managers/nextcloud_manager.dart';
import 'package:yaga/model/nc_login_data.dart';
import 'package:yaga/model/preference.dart';
import 'package:yaga/services/nextcloud_service.dart';
import 'package:yaga/utils/service_locator.dart';
import 'package:yaga/views/screens/nc_address_screen.dart';
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
    getIt.getAsync<NextCloudManager>().then((value) => value.loadLoginDataCommand());

    SectionPreference ncSection = SectionPreference("nc", "Nextcloud");
    StringListPreference mappings = StringListPreference.section(ncSection, "mappings", "Mappings", []);
    _globalAppPreferences.add(ncSection);
    _globalAppPreferences.add(mappings);
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
                if(getIt.get<NextCloudService>().isLoggedIn()) {
                  return Column(
                    children: <Widget>[
                      AvatarWidget.command(getIt.get<NextCloudManager>().updateAvatarCommand),
                      FlatButton(
                        onPressed: () => getIt.get<NextCloudManager>().logoutCommand(), 
                        child: Text("Logout")
                      )
                    ]
                  );
                }

                return FlatButton(
                  onPressed: () => Navigator.pushNamed(context, NextCloudAddressScreen.route), 
                  child: Text("Login")
                );
              }
            )
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