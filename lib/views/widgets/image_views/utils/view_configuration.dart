import 'package:flutter/material.dart';
import 'package:yaga/model/nc_file.dart';
import 'package:yaga/model/preferences/bool_preference.dart';
import 'package:yaga/model/preferences/choice_preference.dart';
import 'package:yaga/model/preferences/preference.dart';
import 'package:yaga/model/preferences/section_preference.dart';
import 'package:yaga/views/widgets/image_views/category_view.dart';
import 'package:yaga/views/widgets/image_views/category_view_exp.dart';
import 'package:yaga/views/widgets/image_views/nc_grid_view.dart';
import 'package:yaga/views/widgets/image_views/nc_list_view.dart';

class ViewConfiguration {
  final SectionPreference section;
  final ChoicePreference view;
  final BoolPreference recursive;
  final BoolPreference showFolders;

  //todo: not sure if moving the onTap handler to this objects is a good idea
  final Function(NcFile) onFolderTap;
  final Function(List<NcFile>, int) onFileTap;
  final Function(NcFile) onSelect;

  ViewConfiguration._internal(this.section, this.view, this.recursive,
      this.showFolders, this.onFileTap, this.onFolderTap, this.onSelect);

  ViewConfiguration clone() {
    return ViewConfiguration._internal(section, view, recursive, showFolders,
        onFileTap, onFolderTap, onSelect);
  }

  factory ViewConfiguration({
    @required String route,
    @required String defaultView,
    @required Function(NcFile) onFolderTap,
    @required Function(List<NcFile>, int) onFileTap,
    @required final Function(NcFile) onSelect,
  }) {
    SectionPreference section = SectionPreference((b) => b
      ..key = Preference.prefixKey(route, "view")
      ..title = "View");
    ChoicePreference view = ChoicePreference((b) => b
      ..key = section.prepareKey("view")
      ..title = "View Type"
      ..value = defaultView
      ..choices = {
        NcListView.viewKey: "List View",
        NcGridView.viewKey: "Grid View",
        CategoryView.viewKey: "Category View",
        CategoryViewExp.viewKey: "Category View (experimental)"
      });
    BoolPreference recursive = BoolPreference((b) => b
      ..key = section.prepareKey("recursive")
      ..title = "Load Recursively"
      ..value = false);
    BoolPreference showFolders = BoolPreference((b) => b
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
    );
  }

  factory ViewConfiguration.browse({
    @required String route,
    @required String defaultView,
    @required Function(NcFile) onFolderTap,
    @required Function(List<NcFile>, int) onFileTap,
    @required Function(NcFile) onSelect,
  }) {
    SectionPreference section = SectionPreference((b) => b
      ..key = Preference.prefixKey(route, "view")
      ..title = "View");
    ChoicePreference view = ChoicePreference((b) => b
      ..key = section.prepareKey("view")
      ..title = "View Type"
      ..value = defaultView
      ..choices = {
        NcListView.viewKey: "List View",
        NcGridView.viewKey: "Grid View"
      });
    BoolPreference recursive = BoolPreference((b) => b
      ..key = section.prepareKey("recursive")
      ..title = "Load Recursively"
      ..value = false);
    BoolPreference showFolders = BoolPreference((b) => b
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
    );
  }

  factory ViewConfiguration.fromViewConfig({
    @required ViewConfiguration viewConfig,
    Function(NcFile) onFolderTap,
    Function(List<NcFile>, int) onFileTap,
    Function(NcFile) onSelect,
  }) {
    return ViewConfiguration._internal(
      viewConfig.section,
      viewConfig.view,
      viewConfig.recursive,
      viewConfig.showFolders,
      onFileTap ?? viewConfig.onFileTap,
      onFolderTap ?? viewConfig.onFolderTap,
      onSelect ?? viewConfig.onSelect,
    );
  }
}
