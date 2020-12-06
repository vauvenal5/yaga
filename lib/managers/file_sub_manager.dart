import 'package:yaga/model/nc_file.dart';

abstract class FileSubManager {
  final String scheme = "";

  Stream<NcFile> listFiles(Uri uri, {bool recursive = false});
  Stream<List<NcFile>> listFileList(Uri uri, {bool recursive = false});
}
