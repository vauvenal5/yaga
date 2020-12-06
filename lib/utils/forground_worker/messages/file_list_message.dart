import 'package:yaga/utils/forground_worker/messages/message.dart';

abstract class FileListMessage extends Message {
  final Uri uri;
  final bool recursive;
  FileListMessage(String key, this.uri, this.recursive) : super(key);
}
