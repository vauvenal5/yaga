import 'package:yaga/model/nc_file.dart';
import 'package:yaga/utils/forground_worker/messages/files_action/files_action_request.dart';

class DeleteFilesRequest extends FilesActionRequest {
  static const String jsonTypeConst = "DeleteFilesRequest";
  static const String _jsonLocal = "local";
  final bool local;

  DeleteFilesRequest({required super.key, required super.files, required super.sourceDir, required this.local})
      : super(jsonType: jsonTypeConst);

  DeleteFilesRequest.fromJson(super.json)
      : local = json[_jsonLocal] as bool,
        super.fromJson();

  @override
  Map<String, dynamic> toJson() {
    return super.toJson()
      ..[_jsonLocal] = local;
  }
}
