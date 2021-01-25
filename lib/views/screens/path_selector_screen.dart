import 'package:flutter/material.dart';
import 'package:yaga/model/nc_file.dart';
import 'package:yaga/model/route_args/directory_navigation_screen_arguments.dart';
import 'package:yaga/views/screens/directory_traversal_screen.dart';
import 'package:yaga/views/widgets/image_views/nc_list_view.dart';
import 'package:yaga/views/widgets/image_views/utils/view_configuration.dart';
import 'package:yaga/views/widgets/select_cancel_bottom_navigation.dart';

//todo: is it a good idea to merge PathSelectorScreen and DirectoryTraversalScreen?
class PathSelectorScreen extends StatelessWidget {
  static const String route = "/pathSelector";

  final Uri _uri;
  final void Function(Uri) _onSelect;
  final void Function(List<NcFile>, int) onFileTap;
  final String title;
  final bool fixedOrigin;

  PathSelectorScreen(
    this._uri,
    this._onSelect, {
    this.onFileTap,
    this.title,
    this.fixedOrigin = false,
  });

  @override
  Widget build(BuildContext context) {
    return DirectoryTraversalScreen(_getArgs(context));
  }

  DirectoryNavigationScreenArguments _getArgs(BuildContext context) {
    Widget Function(BuildContext, Uri) bottomBarBuilder;

    //todo: can't we simply build the bottomBar every time in this screen?
    if (_onSelect != null) {
      bottomBarBuilder =
          (BuildContext context, Uri uri) => SelectCancelBottomNavigation(
                onCommit: () {
                  Navigator.of(context)
                      .pop(DirectoryTraversalScreenNavActions.cancel);
                  _onSelect(uri);
                },
                onCancel: () => Navigator.of(context)
                    .pop(DirectoryTraversalScreenNavActions.cancel),
              );
    }

    ViewConfiguration viewConfig = ViewConfiguration.browse(
      route: route,
      defaultView: NcListView.viewKey,
      onFolderTap: null,
      onFileTap: this.onFileTap,
      onSelect: null,
    );

    return DirectoryNavigationScreenArguments(
        uri: this._uri,
        title: this.title ?? "Select path...",
        viewConfig: viewConfig,
        fixedOrigin: this.fixedOrigin,
        bottomBarBuilder: bottomBarBuilder);
  }
}
