import 'package:yaga/model/sorted_file_list.dart';
import 'package:yaga/utils/forground_worker/messages/message.dart';

class MergeSortRequest extends Message {
  final SortedFileList main;
  final SortedFileList addition;
  final Uri uri;
  final bool recursive;

  MergeSortRequest(
    String key,
    this.main,
    this.addition, {
    this.uri,
    this.recursive = false,
  }) : super(key);
}
