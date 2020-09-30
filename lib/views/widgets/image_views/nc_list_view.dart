import 'package:flutter/material.dart';
import 'package:yaga/model/nc_file.dart';
import 'package:yaga/views/widgets/image_views/utils/view_configuration.dart';
import 'package:yaga/views/widgets/remote_image_widget.dart';

class NcListView extends StatelessWidget {
  static const String viewKey = "list";
  final List<NcFile> files;
  final ViewConfiguration viewConfig;

  final List<NcFile> _files = [];
  final List<NcFile> _folders = [];

  NcListView({
    @required this.files,
    @required this.viewConfig,
  });

  void _sort(List<NcFile> toSort) {
    toSort.forEach((file) {
      if (this.viewConfig.showFolders.value &&
          file.isDirectory &&
          !_folders.contains(file)) {
        _folders.add(file);
      }

      if (!file.isDirectory && !_files.contains(file)) {
        _files.add(file);
      }
    });

    _folders
        .sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    _files.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  @override
  Widget build(BuildContext context) {
    _sort(this.files);

    var slivers = <Widget>[];

    if (this.viewConfig.showFolders.value) {
      slivers.add(SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => ListTile(
            leading: Icon(
              Icons.folder,
              size: 48,
            ),
            isThreeLine: false,
            title: Text(_folders[index].name),
            //todo: move this check into getter of viewConfig
            onTap: this.viewConfig.onFolderTap != null
                ? () => this.viewConfig.onFolderTap(_folders[index])
                : null,
          ),
          childCount: _folders.length,
        ),
      ));
    }

    slivers.add(SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) => ListTile(
          leading: Container(
            width: 64,
            height: 64,
            child: RemoteImageWidget(
              _files[index],
              key: ValueKey(_files[index].uri.path),
              cacheWidth: 128,
            ),
          ),
          // _files[index].localFile==null ?
          //   Image.memory(_files[index].inMemoryPreview, cacheWidth: 32,) :
          //   Image.file(_files[index].localFile, cacheWidth: 32,),
          title: Text(_files[index].name),
          onTap: this.viewConfig.onFileTap != null
              ? () => this.viewConfig.onFileTap(_files, index)
              : null,
        ),
        childCount: _files.length,
      ),
    ));

    return CustomScrollView(
      physics: AlwaysScrollableScrollPhysics(),
      slivers: slivers,
    );
  }
}
