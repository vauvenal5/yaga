import 'package:flutter/material.dart';
import 'package:yaga/managers/widget_local/file_list_local_manager.dart';
import 'package:yaga/model/nc_file.dart';
import 'package:yaga/model/preferences/preference.dart';
import 'package:yaga/model/route_args/directory_navigation_screen_arguments.dart';
import 'package:yaga/model/route_args/focus_view_arguments.dart';
import 'package:yaga/model/route_args/navigatable_screen_arguments.dart';
import 'package:yaga/model/route_args/settings_screen_arguments.dart';
import 'package:yaga/views/screens/focus_view.dart';
import 'package:yaga/views/screens/settings_screen.dart';
import 'package:yaga/views/widgets/image_search.dart';
import 'package:yaga/views/widgets/image_view_container.dart';
import 'package:yaga/views/widgets/image_views/utils/view_configuration.dart';
import 'package:yaga/views/widgets/list_menu_entry.dart';
import 'package:yaga/views/widgets/path_widget.dart';
import 'package:yaga/views/widgets/yaga_popup_menu_button.dart';

enum BrowseViewMenu { settings, focus }

//todo: rename this since it is also used for browse view... maybe clean up a little
class DirectoryTraversalPage extends Page {
  static const String route = "/directoryNavigationScreen";

  final ViewConfiguration viewConfig;
  final FileListLocalManager _fileListLocalManager;
  final String title;
  final Widget Function(BuildContext, Uri) bottomBarBuilder;
  // final Function(Uri) navigate;
  final String navigationRoute;
  final NavigatableScreenArguments Function(DirectoryNavigationScreenArguments)
      getNavigationArgs;
  final bool leading;

  final List<Preference> _defaultViewPreferences = [];
  final bool fixedOrigin;

  DirectoryTraversalPage(
      {@required uri,
      @required this.viewConfig,
      // @required this.navigate,
      this.title,
      this.bottomBarBuilder,
      this.navigationRoute,
      this.getNavigationArgs,
      this.leading,
      this.fixedOrigin = false})
      : _fileListLocalManager = FileListLocalManager(uri, viewConfig.recursive),
        super(key: ValueKey(uri.toString())) {
    this._fileListLocalManager.initState();
    this._defaultViewPreferences.add(this.viewConfig.section);
    this._defaultViewPreferences.add(this.viewConfig.view);
  }

  @override
  Route createRoute(BuildContext context) {
    return MaterialPageRoute(
      settings: this,
      builder: (BuildContext context) => _build(context),
    );
  }

  Widget _build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            this.title ?? this._fileListLocalManager.uri.pathSegments.last),
        leading: this.leading
            ? IconButton(
                icon: Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pop())
            : null,
        actions: <Widget>[
          //todo: image search button goes here
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () async {
              NcFile file = await showSearch<NcFile>(
                context: context,
                delegate: ImageSearch(_fileListLocalManager, this.viewConfig),
              );
              this.viewConfig.onFolderTap(file);
            },
          ),
          YagaPopupMenuButton<BrowseViewMenu>(
            this._buildPopupMenu,
            this._handleMenuSelection,
          ),
        ],
        bottom: PreferredSize(
            child: Container(
              height: 40,
              child: Align(
                alignment: Alignment.topLeft,
                child: PathWidget(
                  this._fileListLocalManager.uri,
                  (Uri subPath) => Navigator.of(context).pop(subPath),
                  // (Uri subPath) => this.navigate(subPath),
                  fixedOrigin: this.fixedOrigin,
                ),
              ),
            ),
            preferredSize: Size.fromHeight(40)),
      ),
      //todo: is it possible to directly pass the folder.uri?
      body: ImageViewContainer(
          fileListLocalManager: _fileListLocalManager,
          viewConfig: this.viewConfig),
      bottomNavigationBar: bottomBarBuilder == null
          ? null
          : bottomBarBuilder(context, this._fileListLocalManager.uri),
    );
  }

  void _handleMenuSelection(BuildContext context, BrowseViewMenu result) {
    if (result == BrowseViewMenu.settings) {
      Navigator.pushNamed(
        context,
        SettingsScreen.route,
        arguments:
            new SettingsScreenArguments(preferences: _defaultViewPreferences),
      );
    }

    if (result == BrowseViewMenu.focus) {
      Navigator.pushNamed(
        context,
        FocusView.route,
        arguments: new FocusViewArguments(_fileListLocalManager.uri),
      );
    }
  }

  List<PopupMenuEntry<BrowseViewMenu>> _buildPopupMenu(BuildContext context) {
    return [
      PopupMenuItem(
        child: ListMenuEntry(Icons.settings, "Settings"),
        value: BrowseViewMenu.settings,
      ),
      PopupMenuItem(
        child: ListMenuEntry(Icons.remove_red_eye, "Focus"),
        value: BrowseViewMenu.focus,
      ),
    ];
  }
}
