import 'dart:io';

import 'package:yaga/model/system_location_host.dart';
import 'package:yaga/utils/uri_utils.dart';

class SystemLocation {
  final Directory directory;
  final String privatePath;
  final String publicPath;
  final SystemLocationHost host;

  SystemLocation(this.directory, this.privatePath, this.publicPath, this.host);
  SystemLocation.fromSplitter(this.directory, this.host, String splitter) : 
    privatePath = directory.path.split(splitter)[0],
    publicPath = splitter+directory.path.split(splitter)[1];

  String get absolutePath => UriUtils.chainPathSegments(privatePath, publicPath);
}