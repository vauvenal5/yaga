import 'package:yaga/utils/forground_worker/messages/message.dart';

abstract class FilesActionRequest extends Message {
  final Uri sourceDir;

  FilesActionRequest(String key, {required this.sourceDir}) : super(key);
}
