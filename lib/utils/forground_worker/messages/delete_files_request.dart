import 'package:yaga/model/nc_file.dart';
import 'package:yaga/utils/forground_worker/messages/message.dart';

class DeleteFilesRequest extends Message {
  final List<NcFile> files;

  DeleteFilesRequest(String key, this.files) : super(key);
}
