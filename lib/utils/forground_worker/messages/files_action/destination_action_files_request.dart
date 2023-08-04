import 'package:yaga/model/nc_file.dart';
import 'package:yaga/utils/forground_worker/messages/files_action/files_action_request.dart';

enum DestinationAction { copy, move }

class DestinationActionFilesRequest extends FilesActionRequest {
  static const String jsonTypeConst = "DestinationActionFilesRequest";
  static const String _jsonFiles = "files";
  static const String _jsonDestination = "destination";
  static const String _jsonAction = "action";
  static const String _jsonOverwrite = "overwrite";

  final List<NcFile> files;
  final Uri destination;
  final DestinationAction action;
  final bool overwrite;

  DestinationActionFilesRequest( {
    required String key,
    required this.files,
    required this.destination,
    required Uri sourceDir,
    this.action = DestinationAction.copy,
    this.overwrite = false,
  }) : super(key, jsonTypeConst, sourceDir: sourceDir);

  DestinationActionFilesRequest.fromJson(Map<String, dynamic> json):
        files = (json[_jsonFiles] as List<dynamic>).map((e) => NcFile.fromJson(e as Map<String, dynamic>)).toList(),
        destination = Uri.parse(json[_jsonDestination] as String),
        action = DestinationAction.values.firstWhere((element) => (json[_jsonAction] as String) == element.name),
        overwrite = json[_jsonOverwrite] as bool,
        super.fromJson(json);

  Map<String, dynamic> toJson() {
    final map = super.toJson();
    map[_jsonFiles] = files.map((e) => e.toJson()).toList();
    map[_jsonDestination] = destination.toString();
    map[_jsonAction] = action.name;
    map[_jsonOverwrite] = overwrite;
    return map;
  }
}
