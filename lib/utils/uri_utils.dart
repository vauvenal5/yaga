import 'package:validators/sanitizers.dart';
import 'package:yaga/model/nc_file.dart';

//todo: refactor into non static functions in util class UriUtils

Uri fromUri({
  required Uri uri,
  String? scheme,
  String? userInfo,
  String? host,
  int? port,
  String? path,
}) =>
    Uri(
      scheme: scheme ?? uri.scheme,
      userInfo: userInfo ?? uri.userInfo,
      host: host ?? uri.host,
      port: port ?? uri.port,
      path: path ?? uri.path,
    );

Uri fromPathList({required Uri uri, required List<String> paths}) {
  String path = "";
  for (final element in paths) {
    path = chainPathSegments(path, element);
  }
  // do not double encode here because paths are already double encoded
  return fromUri(uri: uri, path: path);
}

bool compareFilePathToTargetFilePath(NcFile file, Uri destination) {
  return file.uri.path ==
      chainPathSegments(
        destination.path,
        Uri.encodeComponent(file.name),
      );
}

String chainPathSegments(String first, String second) {
  String firstNormalized = first;
  if (first.endsWith("/")) {
    firstNormalized = rtrim(first, "/");
  }

  String secondNormalized = second;
  if (second.startsWith("/")) {
    secondNormalized = ltrim(second, "/");
  }

  return "$firstNormalized/$secondNormalized";
}

Uri getRootFromUri(Uri uri) => fromUri(uri: uri, path: "/");

Uri fromUriPathSegments(Uri uri, int index) {
  final buffer = StringBuffer();
  buffer.write("/");
  for (int i = 0; i <= index; i++) {
    // in cases where we have encoded chars in the folder name we have to re-encode
    // to make sure we do not change the meaning, since pathSegments does auto-decoding
    buffer.write("${Uri.encodeComponent(uri.pathSegments[i])}/");
  }

  return fromUri(uri: uri, path: buffer.toString());
}

String getNameFromUri(Uri uri) {
  if (uri.pathSegments.isEmpty) {
    return uri.host;
  }

  //resolving any encoded chars in the name of a file/folder to improve readability should be avoided
  //this would not correspond anymore to the displayed name in nextcloud
  //furthermore you get problems when trying to double decode DE chars
  if (uri.pathSegments.last.isNotEmpty) {
    return uri.pathSegments.last;
  }
  return uri.pathSegments[uri.pathSegments.length - 2];
}
