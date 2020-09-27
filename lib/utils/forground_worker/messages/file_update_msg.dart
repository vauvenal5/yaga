import 'package:yaga/model/nc_file.dart';
import 'package:yaga/utils/forground_worker/messages/message.dart';

class FileUpdateMsg extends Message {
  final NcFile file;

  FileUpdateMsg(String key, this.file) : super(key);
}