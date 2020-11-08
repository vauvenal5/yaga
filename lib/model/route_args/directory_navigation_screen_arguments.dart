import 'package:flutter/material.dart';
import 'package:yaga/model/route_args/navigatable_screen_arguments.dart';
import 'package:yaga/views/widgets/image_views/utils/view_configuration.dart';

class DirectoryNavigationScreenArguments extends NavigatableScreenArguments {
  final ViewConfiguration viewConfig;
  final bool leadingBackArrow;
  final String title;
  final Widget Function(BuildContext, Uri) bottomBarBuilder;

  DirectoryNavigationScreenArguments({
    @required Uri uri,
    this.title,
    this.viewConfig,
    this.bottomBarBuilder,
    this.leadingBackArrow = true,
  }) : super(uri: uri);
}
