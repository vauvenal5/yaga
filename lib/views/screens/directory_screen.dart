import 'package:flutter/material.dart';
import 'package:yaga/managers/widget_local/file_list_local_manager.dart';
import 'package:yaga/model/nc_file.dart';
import 'package:yaga/model/preferences/preference.dart';
import 'package:yaga/model/route_args/directory_navigation_screen_arguments.dart';
import 'package:yaga/model/route_args/focus_view_arguments.dart';
import 'package:yaga/model/route_args/navigatable_screen_arguments.dart';
import 'package:yaga/model/route_args/settings_screen_arguments.dart';
import 'package:yaga/services/intent_service.dart';
import 'package:yaga/services/shared_preferences_service.dart';
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
  final String schemeFilter;

  DirectoryScreen({
    @required this.uri,
    @required this.viewConfig,
    this.title,
    this.bottomBarBuilder,
    this.navigationRoute,
    this.getNavigationArgs,
    this.leading,
    this.fixedOrigin = false,
    this.schemeFilter = "",
  }) : super(key: ValueKey(uri.toString()));

  @override
  _DirectoryScreenState createState() => _DirectoryScreenState(uri, viewConfig);
}

class _DirectoryScreenState extends State<DirectoryScreen> {
  final FileListLocalManager _fileListLocalManager;
  final ViewConfiguration _viewConfig;
  final List<Preference> _defaultViewPreferences = [];

  factory _DirectoryScreenState(Uri uri, ViewConfiguration viewConfig) {
    final fileListLocalManager = FileListLocalManager(
      uri,
      viewConfig.recursive,
      ViewConfiguration.getSortConfigFromViewChoice(
        getIt
            .get<SharedPreferencesService>()
            .loadPreferenceFromString(viewConfig.view),
      ),
      allowSelecting: viewConfig.onFileTap != null,
    );

    dynamic onFileTap(List<NcFile> files, int index) {
      if (fileListLocalManager.isInSelectionMode) {
        return fileListLocalManager.selectFileCommand(files[index]);
      }

      if (viewConfig.onFileTap != null) {
        return viewConfig.onFileTap(files, index);
      }
    }

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

  _DirectoryScreenState._internal(this._fileListLocalManager, this._viewConfig);

  @override
  void initState() {
    _defaultViewPreferences.add(widget.viewConfig.section);
    _defaultViewPreferences.add(widget.viewConfig.view);

    _fileListLocalManager.initState();
    super.initState();
  }

  @override
  void dispose() {
    _fileListLocalManager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SelectionWillPopScope(
      fileListLocalManager: _fileListLocalManager,
      child: Scaffold(
        key: ValueKey(_fileListLocalManager.uri.toString()),
        appBar: SelectionAppBar(
          fileListLocalManager: _fileListLocalManager,
          viewConfig: _viewConfig,
          appBarBuilder: _buildAppBar,
          bottomHeight: DirectoryScreen.appBarBottomHeight,
          searchResultHandler: (file) {
            if (file != null && file.isDirectory) {
              widget.viewConfig.onFolderTap(file);
            }
          },
        ),
        //todo: is it possible to directly pass the folder.uri?
        body: ImageViewContainer(
          fileListLocalManager: _fileListLocalManager,
          viewConfig: _viewConfig,
        ),
        bottomNavigationBar: widget.bottomBarBuilder == null
            ? null
            : widget.bottomBarBuilder(context, _fileListLocalManager.uri),
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context, List<Widget> actions) {
    if (!_fileListLocalManager.isInSelectionMode) {
      actions.add(YagaPopupMenuButton<BrowseViewMenu>(
        _buildPopupMenu,
        _handleMenuSelection,
      ));
    }

    return AppBar(
      title: SelectionTitle(
        _fileListLocalManager,
        defaultTitel:
            Text(widget.title ?? _fileListLocalManager.uri.pathSegments.last),
      ),
      //todo: remove widget.leading argument it is always true
      leading: widget.leading
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => _fileListLocalManager.isInSelectionMode
                  ? _fileListLocalManager.deselectAll()
                  : Navigator.of(context).pop())
          : null,
      actions: actions,
      bottom: PreferredSize(
          preferredSize:
              const Size.fromHeight(DirectoryScreen.appBarBottomHeight),
          child: SizedBox(
            height: DirectoryScreen.appBarBottomHeight,
            child: Align(
              alignment: Alignment.topLeft,
              child: PathWidget(
                _fileListLocalManager.uri,
                (Uri subPath) => Navigator.of(context).pop(subPath),
                fixedOrigin: widget.fixedOrigin,
                schemeFilter: widget.schemeFilter,
              ),
            ),
          )),
    );
  }

  void _handleMenuSelection(BuildContext context, BrowseViewMenu result) {
    if (result == BrowseViewMenu.settings) {
      Navigator.pushNamed(
        context,
        SettingsScreen.route,
        arguments:
            SettingsScreenArguments(preferences: _defaultViewPreferences),
      );
    }

    if (result == BrowseViewMenu.focus) {
      Navigator.pushNamed(
        context,
        FocusView.route,
        arguments: FocusViewArguments(_fileListLocalManager.uri),
      );
    }
  }

  List<PopupMenuEntry<BrowseViewMenu>> _buildPopupMenu(BuildContext context) {
    return [
      const PopupMenuItem(
        value: BrowseViewMenu.settings,
        child: ListMenuEntry(Icons.settings, "Settings"),
      ),
      const PopupMenuItem(
        value: BrowseViewMenu.focus,
        child: ListMenuEntry(Icons.remove_red_eye, "Focus"),
      ),
    ];
  }
}
