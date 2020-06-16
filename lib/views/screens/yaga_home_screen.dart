import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:yaga/managers/nextcloud_manager.dart';
import 'package:yaga/managers/settings_manager.dart';
import 'package:yaga/model/nc_login_data.dart';
import 'package:yaga/model/preference.dart';
import 'package:yaga/services/nextcloud_service.dart';
import 'package:yaga/utils/service_locator.dart';
import 'package:yaga/views/screens/nc_address_screen.dart';
import 'package:yaga/views/screens/nc_login_screen.dart';
import 'package:yaga/views/screens/settings_screen.dart';
import 'package:yaga/views/widgets/avatar_widget.dart';
import 'package:yaga/views/widgets/browse_tab.dart';
import 'package:yaga/views/widgets/category_widget.dart';
import 'package:yaga/views/widgets/folder_widget.dart';
import 'package:yaga/views/widgets/path_widget.dart';

enum YagaHomeMenu {settings}
enum YagaHomeTab {grid, folder}

class YagaHomeScreen extends StatefulWidget {
  static const String route = "/";
  
  @override
  State<StatefulWidget> createState() => YagaHomeScreenState();
  
}

class YagaHomeScreenState extends State<YagaHomeScreen> {
  YagaHomeTab _selectedTab;

  final List<Preference> _defaultViewPreferences = [];
  StringPreference _path;

  YagaHomeScreenState() {
    SectionPreference general = SectionPreference.route(YagaHomeScreen.route, "general", "General");
    this._path = StringPreference.section(general, "path", "Path", "");

    this._addAndLoadPreference(general);
    this._defaultViewPreferences.add(_path);
    getIt.get<SettingsManager>().loadDefaultPath(_path);
    // this._addAndLoadPreference(this._path);

    getIt.get<NextCloudManager>().loadLoginDataCommand();
  }

  void _addAndLoadPreference(Preference pref) {
    this._defaultViewPreferences.add(pref);

    if(pref is SectionPreference) {
      return;
    }

    getIt.get<SettingsManager>().newLoadSettingCommand(pref);
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

    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text("Nextcloud Yaga"),
        actions: <Widget>[
          PopupMenuButton<YagaHomeMenu>(
            onSelected: (YagaHomeMenu result) => Navigator.pushNamed(context, SettingsScreen.route, arguments: _defaultViewPreferences),
            itemBuilder: (BuildContext context) => <PopupMenuEntry<YagaHomeMenu>>[
              const PopupMenuItem(child: Text("Settings"), value: YagaHomeMenu.settings),
            ],
          ),
        ],
      ),
      drawer: Drawer(
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
      ),
      body: StreamBuilder<StringPreference>(
        stream: getIt.get<SettingsManager>().newLoadSettingCommand
          .where((event) => event.key == this._path.key)
          .map((event) => event as StringPreference),
        builder: (context, snapshot) {
          if(snapshot.data == null) {
            return LinearProgressIndicator();
          }
          
          switch(this._selectedTab) {
            case YagaHomeTab.folder:
              return BrowseTab(bottomNavBar: bottomNavBar,);
            default:
              return CategoryWidget(Uri.parse(snapshot.data.value));
          }
        },
      ),
      
      bottomNavigationBar: bottomNavBar,
    );
  }
}