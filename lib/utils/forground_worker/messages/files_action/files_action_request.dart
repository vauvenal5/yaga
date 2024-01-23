import 'package:yaga/model/nc_file.dart';
import 'package:yaga/utils/background_worker/json_convertable.dart';

abstract class FilesActionRequest extends JsonConvertable {
  static const String _jsonSourceDir = "sourceDir";
  final Uri sourceDir;
  static const String _jsonFiles = "files";
  final List<NcFile> files;

  FilesActionRequest({
    required String key,
    required String jsonType,
    required this.sourceDir,
    required this.files,
  }) : super(key, jsonType);

  FilesActionRequest.fromJson(super.json)
      : sourceDir = Uri.parse(json[_jsonSourceDir] as String),
        files = (json[_jsonFiles] as List).map((e) => NcFile.fromJson(e as Map<String, dynamic>)).toList(),
        super.fromJson();

  @override
  Map<String, dynamic> toJson() {
    final map = super.toJson();
    map[_jsonSourceDir] = sourceDir.toString();
    map[_jsonFiles] = files.map((e) => e.toJson()).toList();
    return map;
  }
}
