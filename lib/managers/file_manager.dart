import 'package:rx_command/rx_command.dart';
import 'package:yaga/managers/file_manager_base.dart';
import 'package:yaga/model/nc_file.dart';

class FileManager extends FileManagerBase {
  RxCommand<NcFile, NcFile> downloadImageCommand =
      RxCommand.createSync((param) => param);
}
