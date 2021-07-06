import 'package:flutter/material.dart';
import 'package:yaga/managers/widget_local/file_list_local_manager.dart';

class SelectionSelectAll extends StatelessWidget {
  final FileListLocalManager _fileListLocalManager;

  const SelectionSelectAll(this._fileListLocalManager);

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.select_all),
      onPressed: () => _fileListLocalManager.selected.length <
              _fileListLocalManager.sorted.files.length
          ? _fileListLocalManager.selectAll()
          : _fileListLocalManager.deselectAll(),
    );
  }
}
