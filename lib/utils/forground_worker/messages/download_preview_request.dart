import 'package:yaga/model/nc_file.dart';
import 'package:yaga/utils/forground_worker/messages/message.dart';

class DownloadPreviewRequest extends Message {
  final NcFile file;

  DownloadPreviewRequest(String key, this.file) : super(key);
}
