import 'dart:typed_data';

import 'package:yaga/model/nc_file.dart';

class FetchedFile {
  final NcFile file;
  final Uint8List data;

  FetchedFile(this.file, this.data);
}
