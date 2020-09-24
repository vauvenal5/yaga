import 'package:flutter/material.dart';
import 'package:yaga/model/nc_file.dart';
import 'package:yaga/model/preference.dart';
import 'package:yaga/views/widgets/category_widget.dart';
import 'package:yaga/managers/widget_local/file_list_local_manager.dart';

class CategoryView extends StatelessWidget {
  
  final FileListLocalManager _fileListLocalManager;
  final BoolPreference _experimentalView;
  final List<NcFile> Function(List<NcFile>) _filter;

  CategoryView(this._fileListLocalManager, this._experimentalView, {filter = _defaultFilter}) : _filter = filter;

  static List<NcFile> _defaultFilter(List<NcFile> files) => files; 
  
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        StreamBuilder<List<NcFile>>(
          initialData: this._fileListLocalManager.filesChangedCommand.lastResult,
          stream: this._fileListLocalManager.filesChangedCommand,
          builder: (context, snapshot) => CategoryWidget(
            this._filter(snapshot.data), 
            this._experimentalView, 
            () async => this._fileListLocalManager.updateFilesAndFolders()
          ),
        ),
        StreamBuilder<bool>(
          initialData: this._fileListLocalManager.loadingChangedCommand.lastResult,
          stream: this._fileListLocalManager.loadingChangedCommand,
          builder: (context, snapshot) => snapshot.data ? LinearProgressIndicator() : Container(),
        )
      ]
    );
  }
}