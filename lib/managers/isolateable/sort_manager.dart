import 'package:yaga/model/nc_file.dart';
import 'package:yaga/model/sort_config.dart';
import 'package:yaga/model/sorted_category_list.dart';
import 'package:yaga/model/sorted_file_folder_list.dart';
import 'package:yaga/model/sorted_file_list.dart';
import 'package:yaga/utils/forground_worker/isolateable.dart';

class SortManager with Isolateable<SortManager> {
  final Map<
      SortType,
      SortedFileList Function(
    List<NcFile> files,
    List<NcFile> folders,
    SortConfig config,
  )> _sortHandlers = {};
  final Map<SortProperty, void Function(List<NcFile>)> _sortListHandlers = {};
  final Map<SortType, bool Function(SortedFileList, SortedFileList)>
      _mergeSortHandlers = {};
  final Map<SortType, bool Function(SortedFileList, SortedFileList)>
      _mixedMergeHandlers = {};

  SortManager() {
    _sortHandlers[SortType.list] = _sortFileFolders;
    _sortHandlers[SortType.category] = _sortCategory;

    _sortListHandlers[SortProperty.name] = _sortListByName;
    _sortListHandlers[SortProperty.dateModified] = _sortListByDateModified;

    _mergeSortHandlers[SortType.list] =
        (SortedFileList main, SortedFileList addition) {
      if (main is SortedFileFolderList) {
        return _mergeFileFolders(main, addition);
      }
      return false;
    };
    _mergeSortHandlers[SortType.category] =
        (SortedFileList main, SortedFileList addition) {
      if (main is SortedCategoryList && addition is SortedCategoryList) {
        return _mergeCategories(main, addition);
      }
      return false;
    };

    _mixedMergeHandlers[SortType.list] = _mergeSortHandlers[SortType.list]!;
    _mixedMergeHandlers[SortType.category] =
        (SortedFileList main, SortedFileList addition) {
          if(main is SortedCategoryList && addition is SortedFileFolderList) {
            return _mixedMergeCategoryList(main, addition);
          }
          return false;
        };
  }

  bool mergeSort(SortedFileList main, SortedFileList addition) {
    if (main.config.sortType == addition.config.sortType) {
      return _mergeSortHandlers[main.config.sortType]!(main, addition);
    }

    return _mixedMergeHandlers[main.config.sortType]!(main, addition);
  }

  bool _mixedMergeCategoryList(
    SortedCategoryList main,
    SortedFileFolderList addition,
  ) {
    final bool changed = _mergeLists(main.folders, addition.folders, null);
    final SortedCategoryList convertedAddition = sortList(
      addition.files,
      main.config,
    ) as SortedCategoryList;
    return _mergeCategories(main, convertedAddition) || changed;
  }

  bool _mergeFileFolders(
    SortedFileFolderList main,
    SortedFileList addition,
  ) {
    final bool changed = _mergeLists(
      main.files,
      addition.files,
      main.config.fileSortProperty,
    );

    return _mergeLists(
          main.folders,
          addition.folders,
          main.config.folderSortProperty,
        ) ||
        changed;
  }

  bool _mergeCategories(SortedCategoryList main, SortedCategoryList addition) {
    bool changed = false;

    addition.categories
        .where((key) => main.categories.contains(key))
        .map(
          (key) => _mergeLists(
            main.categorizedFiles[key]!,
            addition.categorizedFiles[key]!,
            main.config.fileSortProperty,
          ),
        )
        .forEach((catChanged) => changed = changed || catChanged);

    addition.categories.where((key) => !main.categories.contains(key)).forEach(
      (key) {
        changed = true;
        main.categories.add(key);
        main.categorizedFiles[key] = addition.categorizedFiles[key]!;
      },
    );

    _sortCategories(main.categories);

    return _mergeLists(main.folders, addition.folders, null) || changed;
  }

  bool _mergeLists(
    List<NcFile> main,
    List<NcFile> addition,
    SortProperty? prop,
  ) {
    final size = main.length;

    addition
        .where((element) => !main.contains(element))
        .forEach((element) => main.add(element));

    if (prop != null) {
      _sortListHandlers[prop]!(main);
    }
    return size < main.length;
  }

  SortedFileList sortList(List<NcFile> files, SortConfig config) {
    final List<NcFile> filesToSort = [];
    final List<NcFile> foldersToSort = [];

    for (final file in files) {
      if (file.isDirectory) {
        foldersToSort.add(file);
      } else {
        filesToSort.add(file);
      }
    }

    return _sortHandlers[config.sortType]!(filesToSort, foldersToSort, config);
  }

  SortedFileFolderList _sortFileFolders(
    List<NcFile> files,
    List<NcFile> folders,
    SortConfig config,
  ) {
    _sortListHandlers[config.fileSortProperty]!(files);
    _sortListHandlers[config.folderSortProperty]!(folders);

    return SortedFileFolderList(config, files, folders);
  }

  SortedCategoryList _sortCategory(
    List<NcFile> files,
    List<NcFile> folders,
    SortConfig config,
  ) {
    final sorted = SortedCategoryList(config, folders: folders);

    for (final file in files) {
      final String key = SortedCategoryList.createKey(file);

      if (!sorted.categories.contains(key)) {
        sorted.categories.add(key);
      }

      sorted.categorizedFiles.putIfAbsent(key, () => []);

      if (!sorted.categorizedFiles[key]!.contains(file)) {
        sorted.categorizedFiles[key]!.add(file);
      }
    }

    _sortCategories(sorted.categories);
    sorted.categorizedFiles
        .forEach((key, value) => _sortListByDateModified(value));

    return sorted;
  }

  void _sortListByDateModified(List<NcFile> list) => list.sort(
        (a, b) => b.lastModified!.compareTo(a.lastModified!),
      );

  void _sortListByName(List<NcFile> list) => list.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );

  void _sortCategories(List<String> categories) =>
      categories.sort((date1, date2) => date2.compareTo(date1));
}
