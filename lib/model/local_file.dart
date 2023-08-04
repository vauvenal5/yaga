import 'dart:io';

class LocalFile {
  static const _jsonFileUrl = "fileUrl";
  static const _jsonExists = "exists";

  FileSystemEntity file;
  bool exists;

  LocalFile(this.file, this.exists);

  LocalFile.fromJson(Map<String, dynamic> json, {required bool isDirectory})
      : file = isDirectory
            ? Directory.fromUri(Uri.parse(json[_jsonFileUrl] as String))
            : File.fromUri(Uri.parse(json[_jsonFileUrl] as String)),
        exists = json[_jsonExists] as bool;

  Map<String, dynamic> toJson() {
    return {
      _jsonFileUrl: file.uri.toString(),
      _jsonExists: exists,
    };
  }
}
