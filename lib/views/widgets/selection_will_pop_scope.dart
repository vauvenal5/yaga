import 'package:flutter/material.dart';
import 'package:yaga/managers/widget_local/file_list_local_manager.dart';

class SelectionWillPopScope extends StatelessWidget {
  final Widget child;
  final FileListLocalManager fileListLocalManager;

  SelectionWillPopScope(
      {@required this.child, @required this.fileListLocalManager});

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (this.fileListLocalManager.selectionModeChanged.lastResult) {
          this.fileListLocalManager.deselectAll();
          return false;
        }

        return true;
      },
      child: this.child,
    );
  }
}
