import 'package:flutter/material.dart';
import 'package:yaga/model/sorted_file_folder_list.dart';
import 'package:yaga/views/widgets/image_views/utils/view_configuration.dart';
import 'package:yaga/views/widgets/remote_image_widget.dart';

class NcGridView extends StatelessWidget {
  static const String viewKey = "grid";
  final SortedFileFolderList sorted;
  final ViewConfiguration viewConfig;

  NcGridView(this.sorted, this.viewConfig);

  Widget _buildImage(int key, BuildContext context) {
    return InkWell(
      onTap: () => this.viewConfig.onFileTap(this.sorted.files, key),
      onLongPress: () => this.viewConfig.onSelect(this.sorted.files, key),
      child: RemoteImageWidget(
        this.sorted.files[key],
        key: ValueKey(this.sorted.files[key].uri.path),
        cacheWidth: 256,
        // cacheHeight: 256,
      ),
    );
  }

  Widget _buildFolder(int key, BuildContext context) {
    return Container(
      child: ListTile(
        onTap: () => this.viewConfig.onFolderTap(sorted.folders[key]),
        leading: Icon(
          Icons.folder,
          size: 48,
        ),
        isThreeLine: false,
        contentPadding: EdgeInsets.symmetric(vertical: 4, horizontal: 5),
        title: Text(
          sorted.folders[key].name,
        ),
      ),
      decoration: BoxDecoration(
          border: Border.all(width: 1),
          borderRadius: BorderRadius.all(Radius.circular(10))),
    );
  }

  @override
  Widget build(BuildContext context) {
    SliverGrid folderGrid = SliverGrid(
      delegate: SliverChildBuilderDelegate(
        (context, index) => _buildFolder(index, context),
        childCount: sorted.folders.length,
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
        childCount: sorted.files.length,
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
