import 'package:yaga/model/nc_file.dart';
import 'package:yaga/utils/forground_worker/messages/message.dart';

class DownloadFileRequest extends Message {
  final NcFile file;
  bool forceDownload;

  DownloadFileRequest(
    this.file, {
    this.forceDownload = false,
  }) : super("DownloadFileRequest");
}
