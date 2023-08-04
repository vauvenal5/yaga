import 'package:yaga/model/sorted_file_list.dart';
import 'package:yaga/utils/forground_worker/messages/file_list_message.dart';

class FileListResponse extends FileListMessage {
  final SortedFileList files;

  FileListResponse(String key, Uri uri, this.files, {bool recursive = false})
      : super(key, uri, recursive: recursive);
}
