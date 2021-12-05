import 'package:yaga/model/nc_file.dart';

class PreviewFetchMeta {
  final NcFile file;
  final int fetchIndex;
  final bool success;

  PreviewFetchMeta(this.file, this.fetchIndex, {this.success = true});
}
