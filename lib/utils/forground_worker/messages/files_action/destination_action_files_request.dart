import 'package:yaga/model/nc_file.dart';
import 'package:yaga/model/sort_config.dart';
import 'package:yaga/utils/forground_worker/messages/files_action/files_action_request.dart';

enum DestinationAction { copy, move }

class DestinationActionFilesRequest extends FilesActionRequest {
  final List<NcFile> files;
  final Uri destination;
  final DestinationAction action;
  final bool overwrite;
  final SortConfig config;

  DestinationActionFilesRequest( {
    required String key,
    required this.files,
    required this.config,
    required this.destination,
    required Uri sourceDir,
    this.action = DestinationAction.copy,
    this.overwrite = false,
  }) : super(key, sourceDir: sourceDir);
}
