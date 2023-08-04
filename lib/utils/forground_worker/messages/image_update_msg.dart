import 'package:yaga/model/nc_file.dart';
import 'package:yaga/utils/forground_worker/messages/single_file_message.dart';

class ImageUpdateMsg extends SingleFileMessage {
  static const String jsonTypeConst = "ImageUpdateMsg";

  ImageUpdateMsg(String key, NcFile file) : super(key, jsonTypeConst, file);
  ImageUpdateMsg.fromJson(Map<String, dynamic> json) : super.fromJson(json);
}
