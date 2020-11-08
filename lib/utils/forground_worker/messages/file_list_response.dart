import 'package:yaga/model/nc_file.dart';
import 'package:yaga/utils/forground_worker/messages/file_list_message.dart';
import 'package:yaga/utils/forground_worker/messages/message.dart';

class FileListResponse extends FileListMessage {
  final List<NcFile> files;

  FileListResponse(String key, Uri uri, this.files) : super(key, uri);
}
