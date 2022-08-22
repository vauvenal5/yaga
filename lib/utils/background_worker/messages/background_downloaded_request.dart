import 'package:yaga/model/nc_file.dart';
import 'package:yaga/utils/forground_worker/messages/single_file_message.dart';

class BackgroundDownloadedRequest extends SingleFileMessage {
  static const String jsonTypeConst = "BackgroundDownloadedRequest";
  static const String _jsonSuccess = "success";

  final bool success;

  BackgroundDownloadedRequest({required NcFile file, required this.success})
      : super(jsonTypeConst, jsonTypeConst, file);

  BackgroundDownloadedRequest.fromJson(Map<String, dynamic> json)
      : success = json[_jsonSuccess] as bool,
        super.fromJson(json);

  @override
  Map<String, dynamic> toJson() {
    final map = super.toJson();
    map[_jsonSuccess] = success;
    return map;
  }
}
