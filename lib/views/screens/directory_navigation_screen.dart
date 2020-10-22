import 'package:flutter/material.dart';
import 'package:yaga/managers/widget_local/file_list_local_manager.dart';
import 'package:yaga/model/nc_file.dart';
import 'package:yaga/model/preference.dart';
import 'package:yaga/model/route_args/directory_navigation_screen_arguments.dart';
import 'package:yaga/model/route_args/focus_view_arguments.dart';
import 'package:yaga/model/route_args/navigatable_screen_arguments.dart';
import 'package:yaga/model/route_args/settings_screen_arguments.dart';
import 'package:yaga/utils/uri_utils.dart';
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
class DirectoryNavigationScreen extends StatelessWidget {
  static const String route = "/directoryNavigationScreen";

  final ViewConfiguration viewConfig;
  final FileListLocalManager _fileListLocalManager;
  final String title;
  final Widget Function(BuildContext, Uri) bottomBarBuilder;
  final String navigationRoute;
  final NavigatableScreenArguments Function(DirectoryNavigationScreenArguments)
      getNavigationArgs;

  final List<Preference> _defaultViewPreferences = [];

  DirectoryNavigationScreen(
      {@required uri,
      @required this.viewConfig,
      this.title,
      this.bottomBarBuilder,
      this.navigationRoute,
      this.getNavigationArgs})
      : _fileListLocalManager =
            FileListLocalManager(uri, viewConfig.recursive) {
    this._fileListLocalManager.initState();
    this._defaultViewPreferences.add(this.viewConfig.section);
    this._defaultViewPreferences.add(this.viewConfig.view);
  }

  NavigatableScreenArguments _getSelfArgs(Uri path) {
    var args = DirectoryNavigationScreenArguments(
        uri: path,
        viewConfig: this.viewConfig.clone(),
        title: this.title,
        bottomBarBuilder: this.bottomBarBuilder);

    return this.getNavigationArgs?.call(args) ?? args;
  }

  String _getRoute() => this.navigationRoute ?? DirectoryNavigationScreen.route;

  void _navigateToSelf(BuildContext context, Uri path) {
    Navigator.pushNamed(context, _getRoute(), arguments: _getSelfArgs(path));
  }

  void _popUntilSelf(BuildContext context, Uri path) {
    Navigator.popUntil(context, (route) {
      if (route.settings.arguments is NavigatableScreenArguments) {
        NavigatableScreenArguments args =
            route.settings.arguments as NavigatableScreenArguments;
        if (args.uri.toString() == path.toString()) {
          return true;
        }
        //when the root has to be changed
        if (args.uri.scheme != path.scheme &&
            UriUtils.getRootFromUri(args.uri).toString() ==
                args.uri.toString()) {
          return true;
        }
      }

      return false;
    });

    if (this._fileListLocalManager.uri.scheme != path.scheme) {
      Navigator.pushReplacementNamed(context, _getRoute(),
          arguments: _getSelfArgs(path));
    }
  }

  @override
  Widget build(BuildContext context) {
    this.viewConfig.onFolderTap =
        (NcFile folder) => this._navigateToSelf(context, folder.uri);

    return Scaffold(
      appBar: AppBar(
        title: Text(
            this.title ?? this._fileListLocalManager.uri.pathSegments.last),
        actions: <Widget>[
          //todo: image search button goes here
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () => showSearch(
              context: context,
              delegate: ImageSearch(_fileListLocalManager, this.viewConfig),
            ),
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
                  (Uri subPath) => this._popUntilSelf(context, subPath),
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
