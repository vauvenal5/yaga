import 'package:yaga/utils/background_worker/messages/background_download_request.dart';

class BackgroundDownloadedRequest extends BackgroundDownloadRequest {
  static const String _jsonSuccess = "success";

  final bool success;

  BackgroundDownloadedRequest(
      {required this.success,
      required BackgroundDownloadRequest request})
      : super(uri: request.uri, localFileUri: request.localFileUri, lastModified: request.lastModified);

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
