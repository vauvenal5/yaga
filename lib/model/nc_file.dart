import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;
import 'package:yaga/model/local_file.dart';

class NcFile {
  static const String _jsonIsDirectory = "isDirectory";
  static const String _jsonName = "name";
  static const String _jsonFileExtension = "fileExtension";
  static const String _jsonUri = "uri";
  static const String _jsonUpstreamId = "upstreamId";
  static const String _jsonLocalFile = "localFile";
  static const String _jsonPreviewFile = "previewFile";
  static const String _jsonLastModified = "lastModified";
  static const String _jsonSelected = "selected";
  static const String _jsonFavorite = "favorite";

  final bool isDirectory;
  final String name;
  final String fileExtension;
  Uri uri;
  String? upstreamId;
  LocalFile? localFile;
  LocalFile? previewFile;
  DateTime? lastModified;
  bool selected = false;
  bool favorite = false;

  NcFile(this.uri, this.name, this.fileExtension,
      {required this.isDirectory, this.upstreamId});

  NcFile.fromJson(Map<String, dynamic> json)
      : isDirectory = json[_jsonIsDirectory] as bool,
        name = json[_jsonName] as String,
        fileExtension = json[_jsonFileExtension] as String,
        uri = Uri.parse(json[_jsonUri] as String),
        upstreamId = json[_jsonUpstreamId] == null
            ? null
            : json[_jsonUpstreamId] as String,
        localFile = json[_jsonLocalFile] == null
            ? null
            : LocalFile.fromJson(
                json[_jsonLocalFile] as Map<String, dynamic>,
                isDirectory: json[_jsonIsDirectory] as bool,
              ),
        previewFile = json[_jsonPreviewFile] == null
            ? null
            : LocalFile.fromJson(
                json[_jsonPreviewFile] as Map<String, dynamic>,
                isDirectory: json[_jsonIsDirectory] as bool,
              ),
        lastModified = json[_jsonLastModified] == null
            ? null
            : DateTime.parse(json[_jsonLastModified] as String),
        selected = json[_jsonSelected] as bool,
        favorite = json[_jsonFavorite] as bool;

  factory NcFile.file(Uri uri, String name, String? mime) {
    String ext = p.extension(name).replaceAll('.', '');
    if (ext.isEmpty) {
      ext = extensionFromMime(mime ?? '');
    }
    return NcFile(uri, name, ext, isDirectory: false);
  }

  factory NcFile.directory(Uri uri, String name, {String? upstreamId}) =>
      NcFile(
        uri,
        name,
        '',
        isDirectory: true,
        upstreamId: upstreamId,
      );

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) return false;
    return other is NcFile &&
        other.uri.toString() == uri.toString() &&
        other.upstreamId == upstreamId;
  }

  @override
  int get hashCode => Object.hash(uri, upstreamId);

  Map<String, dynamic> toJson() {
    return {
      _jsonIsDirectory: isDirectory,
      _jsonName: name,
      _jsonFileExtension: fileExtension,
      _jsonUri: uri.toString(),
      _jsonUpstreamId: upstreamId,
      _jsonLocalFile: localFile?.toJson(),
      _jsonPreviewFile: previewFile?.toJson(),
      _jsonLastModified: lastModified?.toString(),
      _jsonSelected: selected,
      _jsonFavorite: favorite
    };
  }
}
