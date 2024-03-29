import 'package:yaga/model/nc_file.dart';
import 'package:yaga/model/preferences/bool_preference.dart';
import 'package:yaga/model/preferences/choice_preference.dart';
import 'package:yaga/model/preferences/preference.dart';
import 'package:yaga/model/preferences/section_preference.dart';
import 'package:yaga/model/sort_config.dart';
import 'package:yaga/views/widgets/image_views/category_view.dart';
import 'package:yaga/views/widgets/image_views/category_view_exp.dart';
import 'package:yaga/views/widgets/image_views/nc_grid_view.dart';
import 'package:yaga/views/widgets/image_views/nc_list_view.dart';

class ViewConfiguration {
  final SectionPreference section;
  final ChoicePreference view;
  final BoolPreference recursive;
  final BoolPreference showFolders;
  final bool favorites;
  final String route;

  //todo: not sure if moving the onTap handler to this objects is a good idea
  final Function(NcFile)? onFolderTap;
  final Function(List<NcFile>, int)? onFileTap;
  final Function(List<NcFile>, int)? onSelect;

  factory ViewConfiguration({
    required String route,
    required String defaultView,
    required Function(NcFile)? onFolderTap,
    required Function(List<NcFile>, int)? onFileTap,
    required final Function(List<NcFile>, int)? onSelect,
    required bool favorites,
  }) {
    final SectionPreference section = SectionPreference((b) => b
      ..key = Preference.prefixKey(route, "view")
      ..title = "View");
    final ChoicePreference view = ChoicePreference((b) => b
      ..key = section.prepareKey("view")
      ..title = "View Type"
      ..value = defaultView
      ..choices = {
        NcListView.viewKey: "List View",
        NcGridView.viewKey: "Grid View",
        CategoryView.viewKey: "Category View",
        CategoryViewExp.viewKey: "Category View (experimental)"
      });
    final BoolPreference recursive = BoolPreference((b) => b
      ..key = section.prepareKey("recursive")
      ..title = "Load Recursively"
      ..value = false);
    final BoolPreference showFolders = BoolPreference((b) => b
      ..key = section.prepareKey("folders")
      ..title = "Show Folders"
      ..value = false);

    return ViewConfiguration._internal(
      section,
      view,
      recursive,
      showFolders,
      onFileTap,
      onFolderTap,
      onSelect,
      route,
      favorites: favorites
    );
  }

  factory ViewConfiguration.browse({
    required String route,
    required String defaultView,
    Function(NcFile)? onFolderTap,
    Function(List<NcFile>, int)? onFileTap,
    Function(List<NcFile>, int)? onSelect,
    bool favorites = false,
  }) {
    final SectionPreference section = SectionPreference((b) => b
      ..key = Preference.prefixKey(route, "view")
      ..title = "View");
    final ChoicePreference view = ChoicePreference((b) => b
      ..key = section.prepareKey("view")
      ..title = "View Type"
      ..value = defaultView
      ..choices = {
        NcListView.viewKey: "List View",
        NcGridView.viewKey: "Grid View"
      });
    final BoolPreference recursive = BoolPreference((b) => b
      ..key = section.prepareKey("recursive")
      ..title = "Load Recursively"
      ..value = false);
    final BoolPreference showFolders = BoolPreference((b) => b
      ..key = section.prepareKey("folders")
      ..title = "Show Folders"
      ..value = true);

    return ViewConfiguration._internal(
      section,
      view,
      recursive,
      showFolders,
      onFileTap,
      onFolderTap,
      onSelect,
      route,
      favorites: favorites,
    );
  }

  factory ViewConfiguration.fromViewConfig({
    required ViewConfiguration viewConfig,
    Function(NcFile)? onFolderTap,
    Function(List<NcFile>, int)? onFileTap,
    Function(List<NcFile>, int)? onSelect,
    bool? favorites,
  }) {
    return ViewConfiguration._internal(
      viewConfig.section,
      viewConfig.view,
      viewConfig.recursive,
      viewConfig.showFolders,
      onFileTap ?? viewConfig.onFileTap,
      onFolderTap ?? viewConfig.onFolderTap,
      onSelect ?? viewConfig.onSelect,
      viewConfig.route,
      favorites: favorites ?? viewConfig.favorites,
    );
  }

  static SortConfig getSortConfigFromViewChoice(ChoicePreference pref) {
    if (pref.value == CategoryView.viewKey ||
        pref.value == CategoryViewExp.viewKey) {
      return const SortConfig(
        SortType.category,
        SortProperty.dateModified,
        SortProperty.name,
      );
    }

    if (pref.value == NcGridView.viewKey) {
      return const SortConfig(
        SortType.list,
        SortProperty.dateModified,
        SortProperty.name,
      );
    }

    return const SortConfig(
      SortType.list,
      SortProperty.name,
      SortProperty.name,
    );
  }

  ViewConfiguration._internal(this.section, this.view, this.recursive,
      this.showFolders, this.onFileTap, this.onFolderTap, this.onSelect, this.route, {this.favorites = false});

  ViewConfiguration clone() {
    return ViewConfiguration._internal(section, view, recursive, showFolders,
        onFileTap, onFolderTap, onSelect, route, favorites: favorites);
  }
}
