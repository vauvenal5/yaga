import 'package:equatable/equatable.dart';

enum SortProperty {
  name,
  dateModified,
}

enum SortType {
  list,
  category,
}

class SortConfig extends Equatable {
  final SortType sortType;
  final SortProperty folderSortProperty;
  final SortProperty fileSortProperty;

  const SortConfig(
      this.sortType, this.fileSortProperty, this.folderSortProperty);

  @override
  List<Object> get props => [sortType, folderSortProperty, fileSortProperty];
}
