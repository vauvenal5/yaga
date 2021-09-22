import 'package:flutter/material.dart';
import 'package:yaga/managers/widget_local/file_list_local_manager.dart';

class SelectionTitle extends StatelessWidget {
  final FileListLocalManager _fileListLocalManager;
  final Widget defaultTitel;

  const SelectionTitle(this._fileListLocalManager, {this.defaultTitel});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: _fileListLocalManager.selectionChangedCommand,
      builder: (context, snapshot) {
        if (defaultTitel != null && !_fileListLocalManager.isInSelectionMode) {
          return defaultTitel;
        }
        return Text(
          "${_fileListLocalManager.selected.length}/${_fileListLocalManager.sorted.files.length}",
          overflow: TextOverflow.fade,
        );
      },
    );
  }
}
