import 'package:flutter/material.dart';
import 'package:yaga/managers/widget_local/file_list_local_manager.dart';
import 'package:yaga/model/nc_file.dart';
import 'package:yaga/views/widgets/image_search.dart';
import 'package:yaga/views/widgets/image_views/utils/view_configuration.dart';

class SearchIconButton extends StatelessWidget {
  final FileListLocalManager fileListLocalManager;
  final ViewConfiguration viewConfig;
  final Function(NcFile) searchResultHandler;

  const SearchIconButton({
    @required this.fileListLocalManager,
    @required this.viewConfig,
    this.searchResultHandler,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.search),
      onPressed: () async {
        final NcFile file = await showSearch<NcFile>(
          context: context,
          delegate: ImageSearch(fileListLocalManager, viewConfig),
        );
        if (searchResultHandler != null) {
          searchResultHandler(file);
        }
      },
    );
  }
}
