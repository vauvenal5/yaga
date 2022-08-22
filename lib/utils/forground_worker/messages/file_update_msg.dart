import 'package:yaga/model/nc_file.dart';
import 'package:yaga/utils/forground_worker/messages/single_file_message.dart';

class FileUpdateMsg extends SingleFileMessage {
  static const String jsonTypeConst = "FileUpdateMsg";

  FileUpdateMsg(String key, NcFile file) : super(key, jsonTypeConst, file);
  FileUpdateMsg.fromJson(Map<String, dynamic> json) : super.fromJson(json);
}
