class UriUtils {
  static const String NCSCHEMA = "nc";
  static const String FILESCHEMA = "file";

  static Uri createNextCloudUri(String path) => Uri(scheme: NCSCHEMA, path: path);
  static Uri createLocalUri(String path) => Uri(scheme: FILESCHEMA, path: path);

  static bool isNextCloudUri(Uri uri) => uri.scheme == NCSCHEMA;
}