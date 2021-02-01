import 'package:yaga/model/nc_file.dart';
import 'package:yaga/model/sort_config.dart';
import 'package:yaga/utils/forground_worker/messages/message.dart';

enum DestinationAction { copy, move }

class DestinationActionFilesRequest extends Message {
  final List<NcFile> files;
  final Uri destination;
  final DestinationAction action;
  final bool overwrite;
  final SortConfig config;

  DestinationActionFilesRequest(
    String key,
    this.files,
    this.destination,
    this.config, {
    this.action = DestinationAction.copy,
    this.overwrite = false,
  }) : super(key);
}
