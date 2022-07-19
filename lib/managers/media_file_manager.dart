import 'package:yaga/managers/file_sub_manager.dart';
import 'package:yaga/model/nc_file.dart';

import 'package:yaga/services/media_file_service.dart';

class MediaFileManager implements FileSubManager {

  final MediaFileService _mediaFileService;


  MediaFileManager(this._mediaFileService);

  @override
  Future<NcFile> copyFile(NcFile file, Uri destination, {bool overwrite = false}) {
    // TODO: implement copyFile
    throw UnimplementedError();
  }

  @override
  Future<NcFile> deleteFile(NcFile file, {required bool local}) {
    // TODO: implement copyFile
    throw UnimplementedError();
  }

  @override
  Stream<List<NcFile>> listFileList(Uri uri, {bool recursive = false}) {
    // TODO: implement listFileList
    throw UnimplementedError();
  }

  @override
  Stream<NcFile> listFiles(Uri uri, {bool recursive = false}) {
    return _mediaFileService.listFiles(uri);
  }

  @override
  Future<NcFile> moveFile(NcFile file, Uri destination, {bool overwrite = false}) {
    // TODO: implement moveFile
    throw UnimplementedError();
  }

  @override
  // todo: currently this is reusing the file-scheme which is meant for local access probably should use a different one?
  String get scheme => _mediaFileService.scheme;
}