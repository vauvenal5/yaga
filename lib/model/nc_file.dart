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

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType)
      return false;
    return other is NcFile
        && other.uri?.toString() == uri?.toString();
  }
}