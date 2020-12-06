import 'package:yaga/model/nc_file.dart';
import 'package:yaga/utils/forground_worker/messages/message.dart';

class DownloadPreviewComplete extends Message {
  final NcFile file;

  DownloadPreviewComplete(String key, this.file) : super(key);
}
