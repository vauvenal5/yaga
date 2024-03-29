import 'package:yaga/model/nc_file.dart';
import 'package:yaga/model/route_args/navigatable_screen_arguments.dart';

class PathSelectorScreenArguments extends NavigatableScreenArguments {
  final void Function(Uri)? onSelect;
  final void Function(List<NcFile>, int)? onFileTap;
  final String? title;
  final bool fixedOrigin;
  final String schemeFilter;

  PathSelectorScreenArguments({
    required Uri uri,
    this.onSelect,
    this.onFileTap,
    this.title,
    this.fixedOrigin = false,
    this.schemeFilter = "",
  }) : super(uri: uri);
}
