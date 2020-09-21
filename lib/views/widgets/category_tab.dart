import 'dart:async';

import 'package:flutter/material.dart';
import 'package:yaga/managers/nextcloud_manager.dart';
import 'package:yaga/managers/settings_manager.dart';
import 'package:yaga/model/preference.dart';
import 'package:yaga/model/route_args/settings_screen_arguments.dart';
import 'package:yaga/services/shared_preferences_service.dart';
import 'package:yaga/services/system_location_service.dart';
import 'package:yaga/utils/service_locator.dart';
import 'package:yaga/views/screens/settings_screen.dart';
import 'package:yaga/views/widgets/category_widget.dart';
import 'package:yaga/views/widgets/image_search.dart';
import 'package:yaga/views/widgets/state_wrappers/category_image_state_wrapper.dart';

enum CategoryViewMenu {settings}

class CategoryTab extends StatefulWidget {

  final Widget bottomNavBar;
  final Widget drawer;

  CategoryTab({@required this.bottomNavBar, @required this.drawer});

  @override
  _CategoryTabState createState() => _CategoryTabState();
}

class _CategoryTabState extends State<CategoryTab> {
  final String _pref = "category";

  final List<Preference> _defaultViewPreferences = [];
  UriPreference _path;
  BoolPreference _experimentalView;
  BoolPreference _recursive;

  StreamSubscription<UriPreference> _updateUriSubscription;
  CategoryImageStateWrapper _imageStateWrapper;

  _CategoryTabState() {
    SectionPreference general = SectionPreference.route(_pref, "general", "General");
    this._path = UriPreference.section(general, "path", "Path", getIt.get<SystemLocationService>().externalAppDirUri);
    this._experimentalView = BoolPreference.section(general, "experimentalView", "Experimental View", true);
    this._recursive = BoolPreference.section(general, "recursiveLoad", "Load Recursively", false);

    this._defaultViewPreferences.add(general);
    this._defaultViewPreferences.add(_path);
    this._defaultViewPreferences.add(_experimentalView);
    this._defaultViewPreferences.add(_recursive);

    //todo: refactor
    getIt.get<NextCloudManager>().logoutCommand.listen((value) => getIt.get<SettingsManager>()
      .persistUriSettingCommand(UriPreference.section(general, "path", "Path", getIt.get<SystemLocationService>().externalAppDirUri))
    );

    this._imageStateWrapper = new CategoryImageStateWrapper(
      this, 
      getIt.get<SharedPreferencesService>().loadUriPreference(this._path).value,
      getIt.get<SharedPreferencesService>().loadBoolPreference(this._recursive)
    );
  }

  @override
  void initState() {
    _updateUriSubscription = getIt.get<SettingsManager>().updateSettingCommand
      .where((event) => event.key == this._path.key)
      .map((event) => event as UriPreference)
      .listen((event) {
        this._imageStateWrapper.uri = event.value;
        this._imageStateWrapper.updateFilesAndFolders();
      });
    
    this._imageStateWrapper.initState();
    super.initState();
  }

  @override
  void dispose() {
    _updateUriSubscription.cancel();
    this._imageStateWrapper.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(CategoryTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    this._imageStateWrapper.updateFilesAndFolders();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text("Nextcloud Yaga"),
        actions: <Widget>[
          //todo: image search button goes here 
          IconButton(icon: Icon(Icons.search), onPressed: () => showSearch(
            context: context, 
            delegate: ImageSearch(_imageStateWrapper.dates, _imageStateWrapper.sortedFiles, this._experimentalView)
          )),
          PopupMenuButton<CategoryViewMenu>(
            onSelected: (CategoryViewMenu result) => Navigator.pushNamed(context, SettingsScreen.route, arguments: new SettingsScreenArguments(preferences: _defaultViewPreferences)),
            itemBuilder: (BuildContext context) => <PopupMenuEntry<CategoryViewMenu>>[
              const PopupMenuItem(child: Text("Settings"), value: CategoryViewMenu.settings),
            ],
          ),
        ],
      ),
      drawer: widget.drawer,
      body: Stack(
        children: [
          CategoryWidget(_imageStateWrapper.dates, _imageStateWrapper.sortedFiles, this._experimentalView),
          this._imageStateWrapper.loading ? LinearProgressIndicator() : Container()
        ]
      ),
      bottomNavigationBar: widget.bottomNavBar,
    );
  }
}