import 'package:flutter/material.dart';
import 'package:yaga/model/sorted_file_folder_list.dart';
import 'package:yaga/views/widgets/image_views/utils/grid_delegate.dart';
import 'package:yaga/views/widgets/image_views/utils/view_configuration.dart';
import 'package:yaga/views/widgets/remote_folder_widget.dart';
import 'package:yaga/views/widgets/remote_image_widget.dart';

class NcGridView extends StatelessWidget with GridDelegate {
  static const String viewKey = "grid";
  final SortedFileFolderList sorted;
  final ViewConfiguration viewConfig;

  const NcGridView(this.sorted, this.viewConfig);

  Widget _buildImage(int key, BuildContext context) {
    return InkWell(
      onTap: () => viewConfig.onFileTap?.call(sorted.files, key),
      onLongPress: () => viewConfig.onSelect?.call(sorted.files, key),
      child: RemoteImageWidget(
        sorted.files[key],
        key: ValueKey(sorted.files[key].uri.path),
        cacheWidth: 256,
        // cacheHeight: 256,
      ),
    );
  }

  Widget _buildFolder(int key, BuildContext context) {
    return Card(
      borderOnForeground: true,
      elevation: 2.0,
      child: Center(
        child: RemoteFolderWidget(index: key, sorted: sorted, viewConfig: viewConfig,)
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final SliverGrid folderGrid = SliverGrid(
      delegate: SliverChildBuilderDelegate(
        (context, index) => _buildFolder(index, context),
        childCount: sorted.folders.length,
      ),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 300.0,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
        mainAxisExtent: 70,
      ),
    );

    final SliverPadding paddedFolders = SliverPadding(
      padding: const EdgeInsets.all(5),
      sliver: folderGrid,
    );

    final SliverGrid fileGrid = SliverGrid(
      gridDelegate: buildImageGridDelegate(context),
      delegate: SliverChildBuilderDelegate(
        (context, index) => _buildImage(index, context),
        childCount: sorted.files.length,
      ),
    );

    final SliverPadding paddedFiles = SliverPadding(
      padding: const EdgeInsets.all(5),
      sliver: fileGrid,
    );

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: viewConfig.showFolders.value
          ? [paddedFolders, paddedFiles]
          : [paddedFiles],
    );
  }
}
