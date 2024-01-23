import 'package:yaga/model/nc_file.dart';
import 'package:yaga/utils/forground_worker/messages/files_action/files_action_request.dart';

enum DestinationAction { copy, move }

class DestinationActionFilesRequest extends FilesActionRequest {
  static const String jsonTypeConst = "DestinationActionFilesRequest";
  static const String _jsonDestination = "destination";
  static const String _jsonAction = "action";
  static const String _jsonOverwrite = "overwrite";

  final Uri destination;
  final DestinationAction action;
  final bool overwrite;

  DestinationActionFilesRequest({
    required super.key,
    required super.files,
    required this.destination,
    required super.sourceDir,
    this.action = DestinationAction.copy,
    this.overwrite = false,
  }) : super(jsonType: jsonTypeConst);

  DestinationActionFilesRequest.fromJson(super.json)
      : destination = Uri.parse(json[_jsonDestination] as String),
        action = DestinationAction.values.firstWhere((element) => (json[_jsonAction] as String) == element.name),
        overwrite = json[_jsonOverwrite] as bool,
        super.fromJson();

  @override
  Map<String, dynamic> toJson() {
    final map = super.toJson();
    map[_jsonDestination] = destination.toString();
    map[_jsonAction] = action.name;
    map[_jsonOverwrite] = overwrite;
    return map;
  }
}
