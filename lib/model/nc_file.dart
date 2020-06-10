import 'dart:io';

import 'dart:typed_data';

class NcFile {
  bool isDirectory;
  String name;
  String path;
  File localFile;
  File previewFile;
  Uint8List inMemoryPreview;
}