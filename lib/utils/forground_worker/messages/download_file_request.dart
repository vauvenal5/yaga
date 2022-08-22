import 'package:yaga/model/nc_file.dart';
import 'package:yaga/utils/forground_worker/messages/single_file_message.dart';

class DownloadFileRequest extends SingleFileMessage {
  static const String jsonTypeConst = "DownloadFileRequest";
  static const String _jsonForceDownload = "forceDownload";

  bool forceDownload;

  DownloadFileRequest(
    NcFile file, {
    this.forceDownload = false,
  }) : super(jsonTypeConst, jsonTypeConst, file);

  DownloadFileRequest.fromJson(Map<String, dynamic> json)
      : forceDownload = json[_jsonForceDownload] as bool,
        super.fromJson(json);

  @override
  Map<String, dynamic> toJson() {
    final superMap = super.toJson();
    superMap[_jsonForceDownload] = forceDownload;
    return superMap;
  }
}
