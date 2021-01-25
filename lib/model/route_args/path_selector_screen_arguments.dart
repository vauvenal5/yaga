import 'package:flutter/foundation.dart';
import 'package:yaga/model/nc_file.dart';
import 'package:yaga/model/route_args/navigatable_screen_arguments.dart';

class PathSelectorScreenArguments extends NavigatableScreenArguments {
  final void Function(Uri) onSelect;
  final void Function(List<NcFile>, int) onFileTap;
  final String title;
  final bool fixedOrigin;

  PathSelectorScreenArguments({
    @required uri,
    this.onSelect,
    this.onFileTap,
    this.title,
    this.fixedOrigin = false,
  }) : super(uri: uri);
}
