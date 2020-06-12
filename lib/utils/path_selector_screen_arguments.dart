import 'package:flutter/foundation.dart';

class PathSelectorScreenArguments {
  final Uri uri;
  final void Function() onCancel;
  final void Function(Uri) onSelect;

  PathSelectorScreenArguments({@required this.uri, @required this.onCancel, @required this.onSelect});
}