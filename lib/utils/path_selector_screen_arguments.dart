import 'package:flutter/foundation.dart';
import 'package:yaga/model/nc_file.dart';

class PathSelectorScreenArguments {
  final Uri uri;
  final void Function() onCancel;
  final void Function(Uri) onSelect;
  final void Function(List<NcFile>, int) onFileTap;

  PathSelectorScreenArguments({@required this.uri, this.onCancel, this.onSelect, this.onFileTap});
}