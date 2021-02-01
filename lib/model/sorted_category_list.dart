import 'package:flutter/material.dart';
import 'package:yaga/model/nc_file.dart';
import 'package:yaga/model/sort_config.dart';
import 'package:yaga/model/sorted_file_list.dart';

class SortedCategoryList extends SortedFileList<SortedCategoryList> {
  final List<NcFile> folders;
  final List<String> categories = [];
  final Map<String, List<NcFile>> categorizedFiles = {};

  SortedCategoryList(
    SortConfig config, {
    @required this.folders,
  }) : super(config);
  factory SortedCategoryList.empty(SortConfig config) =>
      SortedCategoryList(config, folders: []);

  static String createKey(NcFile file) =>
      file.lastModified.toString().split(" ")[0];

  @override
  List<NcFile> get files => categorizedFiles.values.fold(
        [],
        (previousValue, element) => previousValue..addAll(element),
      );

  @override
  bool remove(NcFile file) {
    bool removed = false;
    if (file.isDirectory) {
      removed = folders.remove(file);

      if (removed) {
        categorizedFiles.values.forEach(
          (catFiles) => catFiles.removeWhere(
            (f) => f.uri.path.startsWith(file.uri.path),
          ),
        );

        categorizedFiles.removeWhere((key, value) => value.isEmpty);
      }

      return removed;
    }

    String key = createKey(file);

    if (categorizedFiles.containsKey(key)) {
      removed = categorizedFiles[key].remove(file);

      if (removed && categorizedFiles[key].isEmpty) {
        categories.remove(key);
        categorizedFiles.remove(key);
      }
    }

    return removed;
  }

  @override
  void removeAll() {
    this.categories.clear();
    this.categorizedFiles.clear();
    this.folders.clear();
  }

  @override
  SortedFileList<SortedCategoryList> applyFilter(
    bool Function(NcFile p1) filter,
  ) {
    final filteredFolders = folders
        .where(
          (element) => filter(element),
        )
        .toList();

    final filtered = SortedCategoryList(config, folders: filteredFolders);

    this.categorizedFiles.forEach((key, value) {
      final filteredCat = value
          .where(
            (element) => filter(element),
          )
          .toList();
      if (filteredCat.isNotEmpty) {
        filtered.categories.add(key);
        filtered.categorizedFiles[key] = filteredCat;
      }
    });

    return filtered;
  }
}
