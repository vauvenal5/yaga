import 'package:flutter/material.dart';
import 'package:yaga/managers/settings_manager.dart';
import 'package:yaga/model/preference.dart';
import 'package:yaga/utils/service_locator.dart';
import 'package:yaga/views/screens/folder_screen.dart';
import 'package:yaga/views/screens/settings_screen.dart';

enum YagaHomeMenu {settings}

class YagaHomeScreen extends StatelessWidget {
  static const String route = "/";

  List<Preference> _defaultViewPreferences = [];
  StringPreference _path;

  YagaHomeScreen() {
    SectionPreference general = SectionPreference.route(route, "general", "General");
    this._path = StringPreference.section(general, "path", "Path", "/sdcard/Download");

    this._addAndLoadPreference(general);
    this._addAndLoadPreference(this._path);
  }

  void _addAndLoadPreference(Preference pref) {
    this._defaultViewPreferences.add(pref);

    if(pref is SectionPreference) {
      return;
    }

    getIt.get<SettingsManager>().newLoadSettingCommand(pref);
  }

  @override
  Widget build(BuildContext context) {
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
      body: StreamBuilder<StringPreference>(
        stream: getIt.get<SettingsManager>().newLoadSettingCommand.where((event) => event.key == this._path.key).map((event) => event as StringPreference),
        builder: (context, snapshot) {
          if(snapshot.data == null) {
            return LinearProgressIndicator();
          }
          return FolderScreen(snapshot.data.value, () {});
        },
      ),
      // Center(
      //   // Center is a layout widget. It takes a single child and positions it
      //   // in the middle of the parent.
      //   child: Column(
      //     // Column is also a layout widget. It takes a list of children and
      //     // arranges them vertically. By default, it sizes itself to fit its
      //     // children horizontally, and tries to be as tall as its parent.
      //     //
      //     // Invoke "debug painting" (press "p" in the console, choose the
      //     // "Toggle Debug Paint" action from the Flutter Inspector in Android
      //     // Studio, or the "Toggle Debug Paint" command in Visual Studio Code)
      //     // to see the wireframe for each widget.
      //     //
      //     // Column has various properties to control how it sizes itself and
      //     // how it positions its children. Here we use mainAxisAlignment to
      //     // center the children vertically; the main axis here is the vertical
      //     // axis because Columns are vertical (the cross axis would be
      //     // horizontal).
      //     mainAxisAlignment: MainAxisAlignment.center,
      //     children: <Widget>[
      //       Text(
      //         'You have pushed the button this many times:',
      //       ),
      //       StreamBuilder<String>(
      //         initialData: '0',
      //         stream: getIt.get<CounterManager>().incrementCommand.map((count) => "$count"),
      //         builder: (context, snapshot){ 
      //           return Text(snapshot.data);
      //         }
      //       ),
      //       // Text(
      //       //   '$_counter',
      //       //   style: Theme.of(context).textTheme.display1,
      //       // ),
      //     ],
      //   ),
      // ),
      
      // bottomNavigationBar: BottomNavigationBar(
      //   items: const <BottomNavigationBarItem>[
      //     BottomNavigationBarItem(
      //       icon: Icon(Icons.list),
      //       title: Text('Home'),
      //     ),
      //     BottomNavigationBarItem(
      //       icon: Icon(Icons.folder),
      //       title: Text('Business'),
      //     ),
      //   ],
      // ),
      // floatingActionButton: FloatingActionButton(
      //   onPressed: getIt.get<CounterManager>().incrementCommand,
      //   tooltip: 'Increment',
      //   child: Icon(Icons.add),
      // ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}