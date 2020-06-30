import 'package:flutter/material.dart';
import 'package:yaga/managers/settings_manager.dart';
import 'package:yaga/model/preference.dart';
import 'package:yaga/model/route_args/settings_screen_arguments.dart';
import 'package:yaga/services/local_image_provider_service.dart';
import 'package:yaga/services/shared_preferences_service.dart';
import 'package:yaga/utils/service_locator.dart';
import 'package:yaga/views/screens/settings_screen.dart';
import 'package:yaga/views/widgets/category_widget.dart';

enum CategoryViewMenu {settings}

class CategoryTab extends StatelessWidget {

  final String _pref = "category";

  final List<Preference> _defaultViewPreferences = [];
  UriPreference _path;

  Widget bottomNavBar;
  Widget drawer;

  CategoryTab({@required this.bottomNavBar, @required this.drawer}) {
    SectionPreference general = SectionPreference.route(_pref, "general", "General");
    this._path = UriPreference.section(general, "path", "Path", getIt.get<LocalImageProviderService>().externalAppDirUri);

    this._defaultViewPreferences.add(general);
    this._defaultViewPreferences.add(_path);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text("Nextcloud Yaga"),
        actions: <Widget>[
          PopupMenuButton<CategoryViewMenu>(
            onSelected: (CategoryViewMenu result) => Navigator.pushNamed(context, SettingsScreen.route, arguments: new SettingsScreenArguments(preferences: _defaultViewPreferences)),
            itemBuilder: (BuildContext context) => <PopupMenuEntry<CategoryViewMenu>>[
              const PopupMenuItem(child: Text("Settings"), value: CategoryViewMenu.settings),
            ],
          ),
        ],
      ),
      drawer: drawer,
      body: StreamBuilder<UriPreference>(
        initialData: getIt.get<SharedPreferencesService>().loadUriPreference(this._path),
        stream: getIt.get<SettingsManager>().updateSettingCommand
          .where((event) => event.key == this._path.key)
          .map((event) => event as UriPreference),
        builder: (context, snapshot) {
          if(snapshot.data == null) {
            return LinearProgressIndicator();
          }
        
          return CategoryWidget(snapshot.data.value);
        },
      ),
      bottomNavigationBar: bottomNavBar,
    );
  }

}