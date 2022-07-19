import 'package:yaga/model/nc_file.dart';
import 'package:yaga/utils/forground_worker/messages/file_list_request.dart';
import 'package:yaga/utils/forground_worker/messages/message.dart';

class SortRequest extends Message {
  final List<NcFile> files;
  final FileListRequest fileListRequest;

  SortRequest(String key, this.files, this.fileListRequest) : super(key);
}
