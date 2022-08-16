import 'package:yaga/model/nc_file.dart';
import 'package:yaga/utils/forground_worker/messages/files_action/files_action_request.dart';

class DeleteFilesRequest extends FilesActionRequest {
  final List<NcFile> files;
  final bool local;

  DeleteFilesRequest({
    required String key,
    required this.files,
    required Uri sourceDir,
    required this.local,
  }) : super(key, sourceDir: sourceDir);
}
