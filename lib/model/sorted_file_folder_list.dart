import 'package:yaga/model/nc_file.dart';
import 'package:yaga/model/sort_config.dart';
import 'package:yaga/model/sorted_file_list.dart';

class SortedFileFolderList extends SortedFileList<SortedFileFolderList> {
  final List<NcFile> files;
  final List<NcFile> folders;

  SortedFileFolderList(
    SortConfig config,
    this.files,
    this.folders,
  ) : super(config);

  factory SortedFileFolderList.empty(
    SortConfig config,
  ) =>
      SortedFileFolderList(config, [], []);

  @override
  bool remove(NcFile file) {
    if (file.isDirectory) {
      bool removed = folders.remove(file);

      if (removed) {
        files.removeWhere(
          (element) => element.uri.path.startsWith(file.uri.path),
        );
      }

      return removed;
    }

    return files.remove(file);
  }

  @override
  void removeAll() {
    files.clear();
    folders.clear();
  }

  @override
  SortedFileList<SortedFileFolderList> applyFilter(
    bool Function(NcFile p1) filter,
  ) {
    final filteredFiles = this
        .files
        .where(
          (element) => filter(element),
        )
        .toList();
    final filteredFolders = this
        .folders
        .where(
          (element) => filter(element),
        )
        .toList();
    return SortedFileFolderList(config, filteredFiles, filteredFolders);
  }
}
