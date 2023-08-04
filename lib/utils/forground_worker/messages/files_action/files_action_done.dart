import 'package:yaga/utils/background_worker/json_convertable.dart';

class FilesActionDone extends JsonConvertable {
  static const String jsonTypeConst = "FilesActionDone";
  static const String _jsonDestination = "destination";
  final Uri destination;

  //todo: background: not sure adding destination was the best solution; it only matters for actionDone follow up
  FilesActionDone(String key, this.destination) : super(key, jsonTypeConst);

  FilesActionDone.fromJson(Map<String, dynamic> json)
      : destination = Uri.parse(json[_jsonDestination] as String),
        super.fromJson(json);

  @override
  Map<String, dynamic> toJson() {
    return super.toJson()..[_jsonDestination] = destination.toString();
  }
}
