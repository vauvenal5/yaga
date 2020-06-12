import 'dart:io';

import 'dart:typed_data';

class NcFile {
  bool isDirectory;
  String name;
  Uri uri;
  // String path;
  File localFile;
  File previewFile;
  DateTime lastModified;
}