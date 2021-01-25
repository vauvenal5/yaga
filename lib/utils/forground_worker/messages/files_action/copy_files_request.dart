import 'package:yaga/model/nc_file.dart';
import 'package:yaga/utils/forground_worker/messages/message.dart';

enum DestinationAction { copy, move }

class DestinationActionFilesRequest extends Message {
  final List<NcFile> files;
  final Uri destination;
  final DestinationAction action;

  DestinationActionFilesRequest(
    String key,
    this.files,
    this.destination, {
    this.action = DestinationAction.copy,
  }) : super(key);
}
