import 'dart:io';

import 'dart:typed_data';

class NcFile {
  bool isDirectory;
  String name;
  Uri uri;
  FileSystemEntity localFile;
  FileSystemEntity previewFile;
  DateTime lastModified;

  NcFile(this.uri);

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) return false;
    return other is NcFile && other.uri.toString() == uri.toString();
  }

  @override
  int get hashCode => uri.hashCode;
}
