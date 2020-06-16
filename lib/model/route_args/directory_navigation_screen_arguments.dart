import 'package:flutter/material.dart';
import 'package:yaga/model/nc_file.dart';
import 'package:yaga/model/route_args/navigatable_screen_arguments.dart';

class DirectoryNavigationScreenArguments extends NavigatableScreenArguments {
  final void Function(List<NcFile>, int) onFileTap;
  final String title;
  final Widget Function(BuildContext, Uri) bottomBarBuilder;

  DirectoryNavigationScreenArguments({@required Uri uri, this.title, this.onFileTap, this.bottomBarBuilder}) : super(uri: uri);
}