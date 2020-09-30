import 'package:flutter/material.dart';
import 'package:yaga/model/nc_file.dart';
import 'package:yaga/model/preference.dart';
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
  Function(NcFile) onFolderTap;
  Function(List<NcFile>, int) onFileTap;

  ViewConfiguration._internal(this.section, this.view, this.recursive,
      this.showFolders, this.onFileTap, this.onFolderTap);

  ViewConfiguration clone() {
    return ViewConfiguration._internal(
        section, view, recursive, showFolders, onFileTap, onFolderTap);
  }

  factory ViewConfiguration(
      {@required String route,
      @required String defaultView,
      @required Function(NcFile) onFolderTap,
      @required Function(List<NcFile>, int) onFileTap}) {
    SectionPreference section = SectionPreference.route(route, "view", "View");
    ChoicePreference view =
        ChoicePreference.section(section, "view", "View Type", defaultView, {
      NcListView.viewKey: "List View",
      NcGridView.viewKey: "Grid View",
      CategoryView.viewKey: "Category View",
      CategoryViewExp.viewKey: "Category View (experimental)"
    });
    BoolPreference recursive =
        BoolPreference.section(section, "recursive", "Load Recursively", false);
    BoolPreference showFolders =
        BoolPreference.section(section, "folders", "Show Folders", false);

    return ViewConfiguration._internal(
        section, view, recursive, showFolders, onFileTap, onFolderTap);
  }

  factory ViewConfiguration.browse(
      {@required String route,
      @required String defaultView,
      @required Function(NcFile) onFolderTap,
      @required Function(List<NcFile>, int) onFileTap}) {
    SectionPreference section = SectionPreference.route(route, "view", "View");
    ChoicePreference view =
        ChoicePreference.section(section, "view", "View Type", defaultView, {
      NcListView.viewKey: "List View",
      NcGridView.viewKey: "Grid View",
    });
    BoolPreference recursive =
        BoolPreference.section(section, "recursive", "Load Recursively", false);
    BoolPreference showFolders =
        BoolPreference.section(section, "folders", "Show Folders", true);

    return ViewConfiguration._internal(
        section, view, recursive, showFolders, onFileTap, onFolderTap);
  }
}
