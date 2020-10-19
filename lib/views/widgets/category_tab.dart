import 'dart:async';

import 'package:flutter/material.dart';
import 'package:yaga/managers/nextcloud_manager.dart';
import 'package:yaga/managers/settings_manager.dart';
import 'package:yaga/model/nc_file.dart';
import 'package:yaga/model/preference.dart';
import 'package:yaga/model/route_args/image_screen_arguments.dart';
import 'package:yaga/model/route_args/settings_screen_arguments.dart';
import 'package:yaga/services/shared_preferences_service.dart';
import 'package:yaga/services/isolateable/system_location_service.dart';
import 'package:yaga/utils/service_locator.dart';
import 'package:yaga/views/screens/image_screen.dart';
import 'package:yaga/views/screens/settings_screen.dart';
import 'package:yaga/views/screens/yaga_home_screen.dart';
import 'package:yaga/views/widgets/image_search.dart';
import 'package:yaga/managers/widget_local/file_list_local_manager.dart';
import 'package:yaga/views/widgets/image_views/category_view_exp.dart';
import 'package:yaga/views/widgets/image_view_container.dart';
import 'package:yaga/views/widgets/image_views/utils/view_configuration.dart';
import 'package:yaga/views/widgets/yaga_bottom_nav_bar.dart';

enum CategoryViewMenu { settings }

class CategoryTab extends StatefulWidget {
  final void Function(YagaHomeTab) onTabChanged;
  final Widget drawer;

  CategoryTab({@required this.onTabChanged, @required this.drawer});

  @override
  _CategoryTabState createState() => _CategoryTabState();
}

class _CategoryTabState extends State<CategoryTab>
    with AutomaticKeepAliveClientMixin<CategoryTab> {
  final String _pref = "category";

  final List<Preference> _defaultViewPreferences = [];
  UriPreference _path;
  ViewConfiguration _viewConfig;

  StreamSubscription<UriPreference> _updateUriSubscription;
  FileListLocalManager _fileListLocalManager;

  _CategoryTabState() {
    SectionPreference general =
        SectionPreference.route(_pref, "general", "General");
    this._path = UriPreference.section(general, "path", "Path",
        getIt.get<SystemLocationService>().externalAppDirUri);
    this._viewConfig = ViewConfiguration(
      route: _pref,
      defaultView: CategoryViewExp.viewKey,
      onFolderTap: null,
      onFileTap: (List<NcFile> files, int index) => Navigator.pushNamed(
        context,
        ImageScreen.route,
        arguments: ImageScreenArguments(files, index),
      ),
    );

    this._defaultViewPreferences.add(general);
    this._defaultViewPreferences.add(_path);
    this._defaultViewPreferences.add(this._viewConfig.section);
    this._defaultViewPreferences.add(this._viewConfig.recursive);
    this._defaultViewPreferences.add(this._viewConfig.view);

    //todo: refactor
    getIt.get<NextCloudManager>().logoutCommand.listen((value) => getIt
        .get<SettingsManager>()
        .persistUriSettingCommand(UriPreference.section(general, "path", "Path",
            getIt.get<SystemLocationService>().externalAppDirUri)));

    //todo: is it still necessary for tab to be a stateful widget?
    //image state wrapper ist a widget local manager
    this._fileListLocalManager = new FileListLocalManager(
        getIt
            .get<SharedPreferencesService>()
            .loadUriPreference(this._path)
            .value,
        getIt
            .get<SharedPreferencesService>()
            .loadBoolPreference(this._viewConfig.recursive));
  }

  @override
  void initState() {
    //todo: this could be moved into imageStateWrapper
    _updateUriSubscription = getIt
        .get<SettingsManager>()
        .updateSettingCommand
        .where((event) => event.key == this._path.key)
        .map((event) => event as UriPreference)
        .listen((event) {
      this._fileListLocalManager.uri = event.value;
      this._fileListLocalManager.refetch();
    });

    this._fileListLocalManager.initState();
    super.initState();
  }

  @override
  void dispose() {
    _updateUriSubscription.cancel();
    this._fileListLocalManager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text("Nextcloud Yaga"),
        actions: <Widget>[
          //todo: image search button goes here
          IconButton(
              icon: Icon(Icons.search),
              onPressed: () => showSearch(
                  context: context,
                  delegate:
                      ImageSearch(_fileListLocalManager, this._viewConfig))),
          PopupMenuButton<CategoryViewMenu>(
            onSelected: (CategoryViewMenu result) => Navigator.pushNamed(
                context, SettingsScreen.route,
                arguments: new SettingsScreenArguments(
                    preferences: _defaultViewPreferences)),
            itemBuilder: (BuildContext context) =>
                <PopupMenuEntry<CategoryViewMenu>>[
              const PopupMenuItem(
                  child: Text("Settings"), value: CategoryViewMenu.settings),
            ],
          ),
        ],
      ),
      drawer: widget.drawer,
      body: ImageViewContainer(
          fileListLocalManager: this._fileListLocalManager,
          viewConfig: this._viewConfig),
      bottomNavigationBar:
          YagaBottomNavBar(YagaHomeTab.grid, widget.onTabChanged),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
