import 'package:yaga/model/nc_file.dart';

/// FileServiceManagers are providing basic file manager functions
/// encapsulating required actions for one specific source.
abstract class FileServiceManager {
  final String scheme = "";

  Stream<NcFile> listFiles(Uri uri, {bool recursive = false});
  Stream<List<NcFile>> listFileList(Uri uri, {bool recursive = false, bool favorites = false,});
  Future<NcFile> deleteFile(NcFile file, {required bool local});
  Future<NcFile> copyFile(NcFile file, Uri destination, {bool overwrite = false});
  Future<NcFile> moveFile(NcFile file, Uri destination, {bool overwrite = false});
}
