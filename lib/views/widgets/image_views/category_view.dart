import 'package:flutter/material.dart';
import 'package:yaga/model/nc_file.dart';
import 'package:yaga/model/preference.dart';
import 'package:yaga/views/widgets/category_widget.dart';
import 'package:yaga/views/widgets/state_wrappers/category_image_state_wrapper.dart';

class CategoryView extends StatelessWidget {
  
  final CategoryImageStateWrapper _imageStateWrapper;
  final BoolPreference _experimentalView;
  final List<NcFile> Function(List<NcFile>) _filter;

  CategoryView(this._imageStateWrapper, this._experimentalView, {filter = _defaultFilter}) : _filter = filter;

  static List<NcFile> _defaultFilter(List<NcFile> files) => files; 
  
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        StreamBuilder<List<NcFile>>(
          initialData: this._imageStateWrapper.filesChangedCommand.lastResult,
          stream: this._imageStateWrapper.filesChangedCommand,
          builder: (context, snapshot) => CategoryWidget(
            this._filter(snapshot.data), 
            this._experimentalView, 
            () async => this._imageStateWrapper.updateFilesAndFolders()
          ),
        ),
        StreamBuilder<bool>(
          initialData: this._imageStateWrapper.loadingChangedCommand.lastResult,
          stream: this._imageStateWrapper.loadingChangedCommand,
          builder: (context, snapshot) => snapshot.data ? LinearProgressIndicator() : Container(),
        )
      ]
    );
  }
}