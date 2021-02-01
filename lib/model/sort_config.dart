enum SortProperty {
  name,
  dateModified,
}

enum SortType {
  list,
  category,
}

class SortConfig {
  final SortType sortType;
  final SortProperty folderSortProperty;
  final SortProperty fileSortProperty;

  SortConfig(this.sortType, this.fileSortProperty, this.folderSortProperty);
}
