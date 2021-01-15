import 'package:yaga/model/nc_file.dart';
import 'package:yaga/utils/forground_worker/messages/message.dart';

class ImageUpdateMsg extends Message {
  final NcFile file;
  ImageUpdateMsg(String key, this.file) : super(key);
}
