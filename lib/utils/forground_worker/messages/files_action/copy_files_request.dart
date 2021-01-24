import 'package:yaga/model/nc_file.dart';
import 'package:yaga/utils/forground_worker/messages/message.dart';

class CopyFilesRequest extends Message {
  final List<NcFile> files;
  final Uri destination;

  CopyFilesRequest(String key, this.files, this.destination) : super(key);
}
