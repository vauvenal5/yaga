import 'package:flutter/material.dart';
import 'package:yaga/managers/file_manager/file_manager.dart';
import 'package:yaga/model/nc_file.dart';
import 'package:yaga/model/sorted_file_folder_list.dart';
import 'package:yaga/utils/service_locator.dart';
import 'package:yaga/views/widgets/folder_icon.dart';
import 'package:yaga/views/widgets/image_views/utils/view_configuration.dart';

class RemoteFolderWidget extends StatelessWidget {

  final SortedFileFolderList sorted;
  final int index;
  final ViewConfiguration viewConfig;

  const RemoteFolderWidget({super.key, required this.sorted, required this.index, required this.viewConfig});

  @override
  Widget build(BuildContext context) {
    final folder = sorted.folders[index];
    return  StreamBuilder<NcFile>(stream: getIt.get<FileManager>().updateImageCommand
        .where((event) => event.uri.path == folder.uri.path),
      initialData: folder,
      builder: (context, snapshot) => ListTile(
        onLongPress: () => viewConfig.onSelect?.call(sorted.folders, index),
        onTap: () => viewConfig.onFolderTap?.call(snapshot.data!),
        leading: FolderIcon(dir: snapshot.data!),
        trailing: snapshot.data!.selected ? const Icon(Icons.check_circle) : null,
        title: Text(
          folder.name,
        ),
      ),
    );
  }

}