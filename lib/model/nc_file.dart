import 'dart:io';

class NcFile {
  bool isDirectory;
  String name;
  Uri uri;
  FileSystemEntity localFile;
  FileSystemEntity previewFile;
  DateTime lastModified;
  bool selected = false;

  NcFile(this.uri);

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) return false;
    return other is NcFile && other.uri.toString() == uri.toString();
  }

  @override
  int get hashCode => uri.hashCode;
}
