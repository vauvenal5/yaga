import 'package:yaga/utils/forground_worker/messages/file_list_message.dart';
import 'package:yaga/utils/forground_worker/messages/message.dart';

class FileListDone extends FileListMessage {
  FileListDone(String key, Uri uri) : super(key, uri);
}
