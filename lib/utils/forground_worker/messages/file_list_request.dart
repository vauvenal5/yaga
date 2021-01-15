import 'package:yaga/utils/forground_worker/messages/message.dart';

class FileListRequest extends Message {
  final Uri uri;
  // final List<NcFile> oldFiles;
  final bool recursive;

  FileListRequest(String key, this.uri, this.recursive) : super(key);
}
