import 'package:yaga/model/nc_file.dart';

class SyncFile {
  NcFile file;
  bool remote;

  SyncFile(this.file, {this.remote = false});
}
