import 'package:yaga/model/nc_file.dart';
import 'package:yaga/utils/forground_worker/messages/message.dart';

class DeleteFilesRequest extends Message {
  final List<NcFile> files;
  final bool local;

  DeleteFilesRequest(String key, this.files, this.local) : super(key);
}
