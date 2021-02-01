import 'package:flutter/material.dart';
import 'package:yaga/managers/widget_local/file_list_local_manager.dart';

class SelectionSelectAll extends StatelessWidget {
  final FileListLocalManager _fileListLocalManager;

  SelectionSelectAll(this._fileListLocalManager);

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.select_all),
      onPressed: () => this._fileListLocalManager.selected.length <
              this._fileListLocalManager.sorted.files.length
          ? this._fileListLocalManager.selectAll()
          : this._fileListLocalManager.deselectAll(),
    );
  }
}
