import 'package:yaga/model/nc_file.dart';
import 'package:yaga/model/sort_config.dart';

abstract class SortedFileList<T extends SortedFileList<T>> {
  final SortConfig config;

  SortedFileList(this.config);

  List<NcFile> get files;
  List<NcFile> get folders;

  /// Removes give file or folder from the collection.
  /// If it is a folder then also all files belonging to that folder are removed.
  bool remove(NcFile file);

  void removeAll();

  SortedFileList<T> applyFilter(bool Function(NcFile) filter);
}
