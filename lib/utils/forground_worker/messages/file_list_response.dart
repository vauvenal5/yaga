import 'package:yaga/model/nc_file.dart';
import 'package:yaga/utils/forground_worker/messages/message.dart';

class FileListResponse extends Message {
  final List<NcFile> files;

  FileListResponse(String key, this.files) : super(key);
}