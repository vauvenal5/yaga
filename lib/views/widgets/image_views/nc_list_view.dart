import 'package:flutter/material.dart';
import 'package:yaga/model/sorted_file_folder_list.dart';
import 'package:yaga/views/widgets/image_views/utils/view_configuration.dart';
import 'package:yaga/views/widgets/remote_image_widget.dart';

class NcListView extends StatelessWidget {
  static const String viewKey = "list";
  final SortedFileFolderList sorted;
  final ViewConfiguration viewConfig;

  const NcListView({
    required this.sorted,
    required this.viewConfig,
  });

  @override
  Widget build(BuildContext context) {
    final slivers = <Widget>[];

    if (viewConfig.showFolders.value) {
      slivers.add(SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => ListTile(
            leading: const Icon(
              Icons.folder,
              size: 48,
            ),
            // isThreeLine: false,
            title: Text(sorted.folders[index].name),
            //todo: move this check into getter of viewConfig
            onTap: () => viewConfig.onFolderTap?.call(sorted.folders[index]),
          ),
          childCount: sorted.folders.length,
        ),
      ));
    }

    slivers.add(SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) => ListTile(
          leading: SizedBox(
            width: 64,
            height: 64,
            child: RemoteImageWidget(
              sorted.files[index],
              key: ValueKey(sorted.files[index].uri.path),
              cacheWidth: 128,
              showFileEnding: false,
            ),
          ),
          title: Text(sorted.files[index].name),
          onTap: () => viewConfig.onFileTap?.call(sorted.files, index),
          onLongPress: () => viewConfig.onSelect?.call(sorted.files, index),
        ),
        childCount: sorted.files.length,
      ),
    ));

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: slivers,
    );
  }
}
