import 'dart:io';

import 'package:yaga/utils/uri_utils.dart';

class SystemLocation {
  final String privatePath;
  final String publicPath;
  final Uri absoluteUri;
  final Uri origin;

  SystemLocation(Directory directory, this.origin,) : privatePath = directory.path, publicPath = "", absoluteUri = directory.uri;

  SystemLocation.fromSplitter(Directory directory, this.origin, String splitter)
      : privatePath = directory.path.split(splitter)[0],
        publicPath = splitter + directory.path.split(splitter)[1],
        absoluteUri = directory.uri;

  Uri get uri => fromUri(uri: origin, path: publicPath);
}
