import 'package:yaga/managers/file_service_manager/file_service_manager.dart';
import 'package:yaga/model/nc_file.dart';

import 'package:yaga/services/media_file_service.dart';

class MediaFileManager implements FileServiceManager {
  final MediaFileService _mediaFileService;

  MediaFileManager(this._mediaFileService);

  @override
  Future<NcFile> deleteFile(NcFile file, {required bool local}) {
    return deleteFiles(List.filled(1, file)).then((value) => value.first);
  }

  Future<List<NcFile>> deleteFiles(List<NcFile> files) {
    return _mediaFileService.deleteFile(files);
  }

  @override
  Stream<List<NcFile>> listFileList(Uri uri, {bool recursive = false, bool favorites = false}) {
    // TODO: implement listFileList
    throw UnimplementedError();
  }

  @override
  Stream<NcFile> listFiles(Uri uri, {bool recursive = false}) {
    return _mediaFileService.listFiles(uri);
  }

  @override
  // todo: currently this is reusing the file-scheme which is meant for local access probably should use a different one?
  String get scheme => _mediaFileService.scheme;

  @override
  Future<NcFile> copyFile(NcFile file, Uri destination,
      {bool overwrite = false}) {
    // TODO: implement copyFile
    throw UnimplementedError();
  }

  @override
  Future<NcFile> moveFile(NcFile file, Uri destination,
      {bool overwrite = false}) {
    // TODO: implement moveFile
    throw UnimplementedError();
  }
}
