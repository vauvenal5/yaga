import 'package:yaga/model/nc_file.dart';
import 'package:yaga/utils/forground_worker/messages/files_action/files_action_request.dart';

class FavoriteFilesRequest extends FilesActionRequest {
  static const String jsonTypeConst = "FavoriteFilesRequest";

  FavoriteFilesRequest({required super.key, required super.files, required super.sourceDir})
      : super(jsonType: jsonTypeConst);

  FavoriteFilesRequest.fromJson(super.json) : super.fromJson();
}
