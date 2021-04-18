import 'package:yaga/model/nc_file.dart';
import 'package:yaga/utils/forground_worker/messages/message.dart';

class DownloadFileRequest extends Message {
  final NcFile file;
  bool overrideGlobalPersistFlag;

  DownloadFileRequest(
    this.file, {
    this.overrideGlobalPersistFlag = false,
  }) : super("DownloadFileRequest");
}
