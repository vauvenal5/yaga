import 'package:yaga/utils/background_worker/json_convertable.dart';

abstract class FilesActionRequest extends JsonConvertable {
  static const String _jsonSourceDir = "sourceDir";
  final Uri sourceDir;

  FilesActionRequest(String key, String jsonType, {required this.sourceDir})
      : super(key, jsonType);

  FilesActionRequest.fromJson(Map<String, dynamic> json)
      : sourceDir = Uri.parse(json[_jsonSourceDir] as String),
        super.fromJson(json);

  Map<String, dynamic> toJson() {
    final map = super.toJson();
    map[_jsonSourceDir] = sourceDir.toString();
    return map;
  }
}
