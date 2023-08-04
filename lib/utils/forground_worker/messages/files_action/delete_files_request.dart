import 'package:yaga/model/nc_file.dart';
import 'package:yaga/utils/forground_worker/messages/files_action/files_action_request.dart';

class DeleteFilesRequest extends FilesActionRequest {
  static const String jsonTypeConst = "DeleteFilesRequest";
  static const String _jsonFiles = "files";
  static const String _jsonLocal = "local";
  final List<NcFile> files;
  final bool local;

  DeleteFilesRequest({
    required String key,
    required this.files,
    required Uri sourceDir,
    required this.local,
  }) : super(key, jsonTypeConst, sourceDir: sourceDir);

  DeleteFilesRequest.fromJson(Map<String, dynamic> json)
      : files = (json[_jsonFiles] as List)
            .map((e) => NcFile.fromJson(e as Map<String, dynamic>))
            .toList(),
        local = json[_jsonLocal] as bool,
        super.fromJson(json);

  Map<String, dynamic> toJson() {
    return super.toJson()
      ..[_jsonFiles] = files.map((e) => e.toJson()).toList()
      ..[_jsonLocal] = local;
  }
}
