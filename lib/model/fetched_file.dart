import 'dart:typed_data';

import 'package:yaga/model/nc_file.dart';
import 'package:yaga/utils/forground_worker/messages/message.dart';

class FetchedFile extends Message {
  final NcFile file;
  final Uint8List data;

  FetchedFile(this.file, this.data) : super("FetchedFile");
}
