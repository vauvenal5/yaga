import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;
import 'package:yaga/model/local_file.dart';

class NcFile {
  final bool isDirectory;
  final String name;
  final String fileExtension;
  Uri uri;
  LocalFile localFile;
  LocalFile previewFile;
  DateTime lastModified;
  bool selected = false;

  NcFile(
    this.uri,
    this.name,
    this.fileExtension,
    {this.isDirectory}
  );

  factory NcFile.file(Uri uri, String name, String mime) {
    String ext = p.extension(name).replaceAll('.', '');
    if (ext.isEmpty) {
      ext = extensionFromMime(mime);
    }
    return NcFile(uri, name, ext, isDirectory: false);
  }

  factory NcFile.directory(Uri uri, String name) => NcFile(
        uri,
        name,
        '',
        isDirectory: true,
      );

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) return false;
    return other is NcFile && other.uri.toString() == uri.toString();
  }

  @override
  int get hashCode => uri.hashCode;
}
