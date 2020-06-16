import 'package:flutter/material.dart';
import 'package:yaga/model/nc_file.dart';

class DirectoryNavigationArguments {
  final Uri uri;
  final void Function(List<NcFile>, int) onFileTap;
  final String title;
  final Widget bottomBar;

  DirectoryNavigationArguments({@required this.uri, this.title, this.onFileTap, this.bottomBar});
}