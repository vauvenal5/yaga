import 'package:flutter/material.dart';
import 'package:yaga/model/nc_file.dart';
import 'package:yaga/views/widgets/image_views/utils/view_configuration.dart';
import 'package:yaga/views/widgets/remote_image_widget.dart';

class NcGridView extends StatelessWidget {
  static const String viewKey = "grid";
  final List<NcFile> _files;
  final List<NcFile> _folders;
  final ViewConfiguration viewConfig;

  NcGridView(List<NcFile> files, this.viewConfig)
      : _files = files.where((file) => !file.isDirectory).toList(),
        _folders = files.where((file) => file.isDirectory).toList();

  Widget _buildImage(int key, BuildContext context) {
    return InkWell(
      onTap: () => this.viewConfig.onFileTap(this._files, key),
      onLongPress: () => this.viewConfig.onSelect(this._files, key),
      child: RemoteImageWidget(
        this._files[key],
        key: ValueKey(this._files[key].uri.path),
        cacheWidth: 256,
        // cacheHeight: 256,
      ),
    );
  }

  Widget _buildFolder(int key, BuildContext context) {
    return Container(
      child: ListTile(
        onTap: () => this.viewConfig.onFolderTap(_folders[key]),
        leading: Icon(
          Icons.folder,
          size: 48,
        ),
        isThreeLine: false,
        contentPadding: EdgeInsets.symmetric(vertical: 4, horizontal: 5),
        title: Text(
          _folders[key].name,
        ),
      ),
      decoration: BoxDecoration(
          border: Border.all(width: 1),
          borderRadius: BorderRadius.all(Radius.circular(10))),
    );
  }

  void _sort() {
    if (this.viewConfig.showFolders.value) {
      _folders
          .sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    }
    _files.sort((a, b) => b.lastModified.compareTo(a.lastModified));
  }

  @override
  Widget build(BuildContext context) {
    _sort();

    SliverGrid folderGrid = SliverGrid(
      delegate: SliverChildBuilderDelegate(
        (context, index) => _buildFolder(index, context),
        childCount: _folders.length,
      ),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 5,
        mainAxisSpacing: 5,
        childAspectRatio: 3,
      ),
    );

    SliverPadding paddedFolders = SliverPadding(
      padding: EdgeInsets.all(5),
      sliver: folderGrid,
    );

    SliverGrid fileGrid = SliverGrid(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) => _buildImage(index, context),
        childCount: _files.length,
      ),
    );

    SliverPadding paddedFiles = SliverPadding(
      padding: EdgeInsets.all(5),
      sliver: fileGrid,
    );

    return CustomScrollView(
      physics: AlwaysScrollableScrollPhysics(),
      slivers: this.viewConfig.showFolders.value
          ? [paddedFolders, paddedFiles]
          : [paddedFiles],
    );
  }
}
