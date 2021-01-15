import 'package:flutter/material.dart';
import 'package:yaga/managers/widget_local/file_list_local_manager.dart';

class SelectionTitle extends StatelessWidget {
  final FileListLocalManager _fileListLocalManager;
  final Widget defaultTitel;

  SelectionTitle(this._fileListLocalManager, {this.defaultTitel});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: this._fileListLocalManager.selectionChangedCommand,
      builder: (context, snapshot) {
        if (this.defaultTitel != null &&
            !this._fileListLocalManager.isInSelectionMode) {
          return defaultTitel;
        }
        return Text(
          "${this._fileListLocalManager.selected.length}/${this._fileListLocalManager.files.length}",
          overflow: TextOverflow.fade,
        );
      },
    );
  }
}
