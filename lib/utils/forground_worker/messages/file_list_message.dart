import 'package:yaga/utils/forground_worker/messages/message.dart';

abstract class FileListMessage extends Message {
  final Uri uri;
  FileListMessage(String key, this.uri) : super(key);
}
