import 'dart:io';

import 'package:permission_handler/permission_handler.dart';
import 'package:rxdart/rxdart.dart';

class LocalImageProviderService {

  Stream<FileSystemEntity> searchDir(String directory) {
    return Permission.storage.request().asStream()
      .where((event) => event.isGranted)
      .map((event) => new Directory(directory))
      .flatMap((dir) => dir.list(recursive: false, followLinks: false)
        //.where((entity) => entity is File)
        //.map((entity) => entity as File)
        //.where((file) => file.path.endsWith(".bmp") || file.path.endsWith(".jpg"))
      );
  }
}