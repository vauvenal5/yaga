import 'package:flutter/foundation.dart';
import 'package:yaga/model/nc_file.dart';
import 'package:yaga/model/route_args/navigatable_screen_arguments.dart';

class PathSelectorScreenArguments extends NavigatableScreenArguments {
  final void Function() onCancel;
  final void Function(Uri) onSelect;
  final void Function(List<NcFile>, int) onFileTap;
  final String title;

  PathSelectorScreenArguments({@required uri, this.onCancel, this.onSelect, this.onFileTap, this.title}) : super(uri: uri);
}