import 'package:yaga/model/sorted_file_list.dart';
import 'package:yaga/utils/forground_worker/messages/message.dart';

class MergeSortDone extends Message {
  final SortedFileList sorted;

  MergeSortDone(String key, this.sorted) : super(key);
}
