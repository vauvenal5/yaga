import 'package:yaga/utils/forground_worker/messages/file_list_message.dart';

class FileListDone extends FileListMessage {
  FileListDone(String key, Uri uri, {bool recursive = false})
      : super(key, uri, recursive: recursive);
}
