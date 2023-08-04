import 'package:flutter/material.dart';
import 'package:yaga/managers/widget_local/file_list_local_manager.dart';
import 'package:yaga/model/nc_file.dart';
import 'package:yaga/views/widgets/image_views/utils/view_configuration.dart';
import 'package:yaga/views/widgets/search_icon_button.dart';
import 'package:yaga/views/widgets/selection_popup_menu_button.dart';
import 'package:yaga/views/widgets/selection_select_all.dart';

class SelectionAppBar extends PreferredSize {
  factory SelectionAppBar({
    required FileListLocalManager fileListLocalManager,
    required ViewConfiguration viewConfig,
    required Widget Function(BuildContext, List<Widget>) appBarBuilder,
    double bottomHeight = 0,
    Function(NcFile?)? searchResultHandler,
  }) {
    final Widget child = StreamBuilder(
      initialData: fileListLocalManager.selectionModeChanged.lastResult,
      stream: fileListLocalManager.selectionModeChanged,
      builder: (context, snapshot) {
        final List<Widget> actions = [];
        if (fileListLocalManager.isInSelectionMode) {
          actions.add(SelectionSelectAll(fileListLocalManager));
        }

        actions.add(SearchIconButton(
          fileListLocalManager: fileListLocalManager,
          viewConfig: viewConfig,
          searchResultHandler: searchResultHandler,
        ));

        if (fileListLocalManager.isInSelectionMode) {
          actions.add(SelectionPopupMenuButton(
            fileListLocalManager: fileListLocalManager,
          ));
        }

        return appBarBuilder(context, actions);
      },
    );

    return SelectionAppBar._internal(
      preferredSize: Size.fromHeight(kToolbarHeight + bottomHeight),
      child: child,
    );
  }

  const SelectionAppBar._internal({
    required Size preferredSize,
    required Widget child,
  }) : super(preferredSize: preferredSize, child: child);
}
