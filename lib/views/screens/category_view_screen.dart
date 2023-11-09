import 'dart:async';

import 'package:flutter/material.dart';
import 'package:yaga/managers/nextcloud_manager.dart';
import 'package:yaga/managers/settings_manager.dart';
import 'package:yaga/model/category_view_config.dart';
import 'package:yaga/model/nc_file.dart';
import 'package:yaga/model/preferences/preference.dart';
import 'package:yaga/model/preferences/uri_preference.dart';
import 'package:yaga/model/route_args/image_screen_arguments.dart';
import 'package:yaga/model/route_args/settings_screen_arguments.dart';
import 'package:yaga/services/intent_service.dart';
import 'package:yaga/services/shared_preferences_service.dart';
import 'package:yaga/services/isolateable/system_location_service.dart';
import 'package:yaga/utils/service_locator.dart';
import 'package:yaga/views/screens/image_screen.dart';
import 'package:yaga/views/screens/settings_screen.dart';
import 'package:yaga/managers/widget_local/file_list_local_manager.dart';
import 'package:yaga/views/widgets/image_views/category_view_exp.dart';
import 'package:yaga/views/widgets/image_view_container.dart';
import 'package:yaga/views/widgets/image_views/utils/view_configuration.dart';
import 'package:yaga/views/widgets/list_menu_entry.dart';
import 'package:yaga/views/widgets/selection_app_bar.dart';
import 'package:yaga/views/widgets/selection_title.dart';
import 'package:yaga/views/widgets/selection_will_pop_scope.dart';
import 'package:yaga/views/widgets/yaga_bottom_nav_bar.dart';
import 'package:yaga/views/widgets/yaga_drawer.dart';
import 'package:yaga/views/widgets/yaga_popup_menu_button.dart';

enum CategoryViewMenu { settings }

abstract class CategoryViewScreen extends StatefulWidget {
  final CategoryViewConfig _categoryViewConfig;

  const CategoryViewScreen(this._categoryViewConfig);

  @override
  _CategoryViewScreenState createState() => _CategoryViewScreenState();
}

class _CategoryViewScreenState extends State<CategoryViewScreen>
    with AutomaticKeepAliveClientMixin<CategoryViewScreen> {
  final List<Preference> _defaultViewPreferences = [];
  late ViewConfiguration _viewConfig;

  // GeneralViewConfig _generalViewConfig;

  late StreamSubscription<UriPreference> _updateUriSubscription;
  late FileListLocalManager _fileListLocalManager;

  @override
  void initState() {
    void onFileTap(List<NcFile> files, int index) =>
        _fileListLocalManager.isInSelectionMode
            ? _fileListLocalManager.selectFileCommand(files[index])
            //todo: replace navigation by navigation manager
            : Navigator.pushNamed(
                context,
                ImageScreen.route,
                arguments: ImageScreenArguments(files, index),
              );

    _viewConfig = ViewConfiguration(
      route: widget._categoryViewConfig.pref,
      defaultView: CategoryViewExp.viewKey,
      onFolderTap: null,
      onFileTap: onFileTap,
      onSelect: getIt.get<IntentService>().isOpenForSelect
          ? onFileTap
          : (files, index) =>
              _fileListLocalManager.selectFileCommand(files[index]),
      favorites: widget._categoryViewConfig.favorites
    );

    _defaultViewPreferences
        .add(widget._categoryViewConfig.generalViewConfig.general);
    _defaultViewPreferences
        .add(widget._categoryViewConfig.generalViewConfig.path);
    _defaultViewPreferences.add(_viewConfig.section);
    _defaultViewPreferences.add(_viewConfig.recursive);
    _defaultViewPreferences.add(_viewConfig.view);

    //todo: refactor
    getIt.get<NextCloudManager>().logoutCommand.listen((value) => getIt
        .get<SettingsManager>()
        .persistStringSettingCommand(
            widget._categoryViewConfig.generalViewConfig.path.rebuild(
          (b) =>
              b..value = getIt.get<SystemLocationService>().internalStorage.uri,
        )));

    //todo: is it still necessary for tab to be a stateful widget?
    //image state wrapper is a widget local manager
    _fileListLocalManager = FileListLocalManager(
      getIt
          .get<SharedPreferencesService>()
          .loadPreferenceFromString(
              widget._categoryViewConfig.generalViewConfig.path)
          .value,
      getIt
          .get<SharedPreferencesService>()
          .loadPreferenceFromBool(_viewConfig.recursive),
      ViewConfiguration.getSortConfigFromViewChoice(
        getIt
            .get<SharedPreferencesService>()
            .loadPreferenceFromString(_viewConfig.view),
      ),
      favorites: _viewConfig.favorites,
    );

    //todo: this could be moved into imageStateWrapper
    _updateUriSubscription = getIt
        .get<SettingsManager>()
        .updateSettingCommand
        .where((event) =>
            event.key == widget._categoryViewConfig.generalViewConfig.path.key)
        .map((event) => event as UriPreference)
        .listen((event) {
      _fileListLocalManager.refetch(uri: event.value);
    });

    _fileListLocalManager.initState();
    super.initState();
  }

  @override
  void dispose() {
    _updateUriSubscription.cancel();
    _fileListLocalManager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return SelectionWillPopScope(
      fileListLocalManager: _fileListLocalManager,
      child: Scaffold(
        appBar: SelectionAppBar(
          fileListLocalManager: _fileListLocalManager,
          viewConfig: _viewConfig,
          appBarBuilder: _buildAppBar,
        ),
        drawer: widget._categoryViewConfig.hasDrawer! ? YagaDrawer() : null,
        body: ImageViewContainer(
            fileListLocalManager: _fileListLocalManager,
            viewConfig: _viewConfig),
        bottomNavigationBar:
            YagaBottomNavBar(widget._categoryViewConfig.selectedTab!),
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context, List<Widget> actions) {
    if (!_fileListLocalManager.isInSelectionMode) {
      actions.add(YagaPopupMenuButton<CategoryViewMenu>(
        _buildPopupMenu,
        _popupMenuHandler,
      ));
    }

    return AppBar(
      title: SelectionTitle(
        _fileListLocalManager,
        defaultTitel: Text(
          widget._categoryViewConfig.title!,
          overflow: TextOverflow.fade,
        ),
      ),
      actions: actions,
      leading: _fileListLocalManager.isInSelectionMode
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => _fileListLocalManager.deselectAll(),
            )
          : null,
    );
  }

  void _popupMenuHandler(BuildContext context, CategoryViewMenu result) {
    if (result == CategoryViewMenu.settings) {
      Navigator.pushNamed(
        context,
        SettingsScreen.route,
        arguments: SettingsScreenArguments(
          preferences: _defaultViewPreferences,
        ),
      );
    }
  }

  List<PopupMenuEntry<CategoryViewMenu>> _buildPopupMenu(BuildContext context) {
    return [
      const PopupMenuItem(
        value: CategoryViewMenu.settings,
        child: ListMenuEntry(Icons.settings, "Settings"),
      ),
    ];
  }

  @override
  bool get wantKeepAlive => true;
}
