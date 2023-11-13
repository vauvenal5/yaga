import 'package:flutter/material.dart';
import 'package:yaga/model/sorted_file_folder_list.dart';
import 'package:yaga/views/widgets/folder_icon.dart';
import 'package:yaga/views/widgets/image_views/utils/view_configuration.dart';
import 'package:yaga/views/widgets/remote_image_widget.dart';

class NcGridView extends StatelessWidget {
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
    return Container(
      decoration: BoxDecoration(
          border: Border.all(/* width: 1 */),
          borderRadius: const BorderRadius.all(Radius.circular(10))),
      child: ListTile(
        onTap: () => viewConfig.onFolderTap?.call(sorted.folders[key]),
        leading: FolderIcon(dir: sorted.folders[key]),
        // isThreeLine: false,
        contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 5),
        title: Text(
          sorted.folders[key].name,
        ),
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
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 5,
        mainAxisSpacing: 5,
        childAspectRatio: 3,
      ),
    );

    final SliverPadding paddedFolders = SliverPadding(
      padding: const EdgeInsets.all(5),
      sliver: folderGrid,
    );

    final SliverGrid fileGrid = SliverGrid(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
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
