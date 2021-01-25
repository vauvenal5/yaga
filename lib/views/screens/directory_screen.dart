import 'package:flutter/material.dart';
import 'package:yaga/managers/widget_local/file_list_local_manager.dart';
import 'package:yaga/model/preferences/preference.dart';
import 'package:yaga/model/route_args/directory_navigation_screen_arguments.dart';
import 'package:yaga/model/route_args/focus_view_arguments.dart';
import 'package:yaga/model/route_args/navigatable_screen_arguments.dart';
import 'package:yaga/model/route_args/settings_screen_arguments.dart';
import 'package:yaga/services/intent_service.dart';
import 'package:yaga/utils/service_locator.dart';
import 'package:yaga/views/screens/focus_view.dart';
import 'package:yaga/views/screens/settings_screen.dart';
import 'package:yaga/views/widgets/image_view_container.dart';
import 'package:yaga/views/widgets/image_views/utils/view_configuration.dart';
import 'package:yaga/views/widgets/list_menu_entry.dart';
import 'package:yaga/views/widgets/path_widget.dart';
import 'package:yaga/views/widgets/selection_app_bar.dart';
import 'package:yaga/views/widgets/selection_title.dart';
import 'package:yaga/views/widgets/selection_will_pop_scope.dart';
import 'package:yaga/views/widgets/yaga_popup_menu_button.dart';

enum BrowseViewMenu { settings, focus }

//todo: rename this since it is also used for browse view... maybe clean up a little
class DirectoryScreen extends StatefulWidget {
  static const String route = "/directoryNavigationScreen";
  static const double appBarBottomHeight = 40;

  final ViewConfiguration viewConfig;
  final Uri uri;
  final String title;
  final Widget Function(BuildContext, Uri) bottomBarBuilder;
  final String navigationRoute;
  final NavigatableScreenArguments Function(DirectoryNavigationScreenArguments)
      getNavigationArgs;
  final bool leading;

  final bool fixedOrigin;

  DirectoryScreen(
      {@required this.uri,
      @required this.viewConfig,
      this.title,
      this.bottomBarBuilder,
      this.navigationRoute,
      this.getNavigationArgs,
      this.leading,
      this.fixedOrigin = false})
      : super(key: ValueKey(uri.toString()));

  @override
  _DirectoryScreenState createState() =>
      _DirectoryScreenState(this.uri, this.viewConfig);
}

class _DirectoryScreenState extends State<DirectoryScreen> {
  final FileListLocalManager _fileListLocalManager;
  final ViewConfiguration _viewConfig;
  List<Preference> _defaultViewPreferences = [];

  _DirectoryScreenState._internal(this._fileListLocalManager, this._viewConfig);

  factory _DirectoryScreenState(Uri uri, ViewConfiguration viewConfig) {
    final fileListLocalManager = FileListLocalManager(
      uri,
      viewConfig.recursive,
      allowSelecting: viewConfig.onFileTap != null,
    );

    final onFileTap = (files, index) {
      if (fileListLocalManager.isInSelectionMode) {
        return fileListLocalManager.selectFileCommand(files[index]);
      }

      if (viewConfig.onFileTap != null) {
        return viewConfig.onFileTap(files, index);
      }
    };

    return _DirectoryScreenState._internal(
      fileListLocalManager,
      ViewConfiguration.fromViewConfig(
        viewConfig: viewConfig,
        onFolderTap: (folder) {
          if (fileListLocalManager.isInSelectionMode) {
            return;
          }
          return viewConfig.onFolderTap(folder);
        },
        onSelect: getIt.get<IntentService>().isOpenForSelect
            ? onFileTap
            : (files, index) =>
                fileListLocalManager.selectFileCommand(files[index]),
        onFileTap: onFileTap,
      ),
    );
  }

  @override
  void initState() {
    this._defaultViewPreferences.add(widget.viewConfig.section);
    this._defaultViewPreferences.add(widget.viewConfig.view);

    this._fileListLocalManager.initState();
    super.initState();
  }

  @override
  void dispose() {
    this._fileListLocalManager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SelectionWillPopScope(
      fileListLocalManager: this._fileListLocalManager,
      child: Scaffold(
        key: ValueKey(this._fileListLocalManager.uri.toString()),
        appBar: SelectionAppBar(
          fileListLocalManager: _fileListLocalManager,
          viewConfig: _viewConfig,
          appBarBuilder: _buildAppBar,
          bottomHeight: DirectoryScreen.appBarBottomHeight,
          searchResultHandler: (file) {
            if (file != null && file.isDirectory) {
              this.widget.viewConfig.onFolderTap(file);
            }
          },
        ),
        //todo: is it possible to directly pass the folder.uri?
        body: ImageViewContainer(
          fileListLocalManager: _fileListLocalManager,
          viewConfig: this._viewConfig,
        ),
        bottomNavigationBar: widget.bottomBarBuilder == null
            ? null
            : widget.bottomBarBuilder(context, this._fileListLocalManager.uri),
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context, List<Widget> actions) {
    if (!_fileListLocalManager.isInSelectionMode) {
      actions.add(YagaPopupMenuButton<BrowseViewMenu>(
        this._buildPopupMenu,
        this._handleMenuSelection,
      ));
    }

    return AppBar(
      title: SelectionTitle(
        this._fileListLocalManager,
        defaultTitel: Text(this.widget.title ??
            this._fileListLocalManager.uri.pathSegments.last),
      ),
      //todo: remove widget.leading argument it is always true
      leading: this.widget.leading
          ? IconButton(
              icon: Icon(Icons.arrow_back),
              onPressed: () => _fileListLocalManager.isInSelectionMode
                  ? _fileListLocalManager.deselectAll()
                  : Navigator.of(context).pop())
          : null,
      actions: actions,
      bottom: PreferredSize(
          child: Container(
            height: DirectoryScreen.appBarBottomHeight,
            child: Align(
              alignment: Alignment.topLeft,
              child: PathWidget(
                this._fileListLocalManager.uri,
                (Uri subPath) => Navigator.of(context).pop(subPath),
                fixedOrigin: this.widget.fixedOrigin,
              ),
            ),
          ),
          preferredSize: Size.fromHeight(DirectoryScreen.appBarBottomHeight)),
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
