class BackgroundDownloadRequest {
  static const String _jsonUri = "uri";
  static const String _jsonLocalFileUri = "localFileUri";
  static const String _jsonLastModified = "lastModified";

  final Uri uri;
  final Uri localFileUri;
  final DateTime lastModified;

  BackgroundDownloadRequest({required this.uri, required this.localFileUri, required this.lastModified});

  BackgroundDownloadRequest.fromJson(Map<String, dynamic> json)
      : uri = Uri.parse(json[_jsonUri] as String),
        localFileUri = Uri.parse(json[_jsonLocalFileUri] as String),
        lastModified = DateTime.parse(json[_jsonLastModified] as String);

  Map<String, dynamic> toJson() {
    return {
      _jsonUri: uri.toString(),
      _jsonLocalFileUri: localFileUri.toString(),
      _jsonLastModified: lastModified.toString(),
    };
  }
}
