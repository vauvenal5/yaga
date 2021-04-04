import 'package:yaga/model/nc_file.dart';
import 'package:yaga/utils/forground_worker/messages/message.dart';

class DownloadFileRequest extends Message {
  final NcFile file;

  DownloadFileRequest(this.file) : super("DownloadFileRequest");
}
