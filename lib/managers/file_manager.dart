import 'package:rx_command/rx_command.dart';
import 'package:yaga/managers/file_manager_base.dart';
import 'package:yaga/utils/forground_worker/messages/download_file_request.dart';

class FileManager extends FileManagerBase {
  RxCommand<DownloadFileRequest, DownloadFileRequest> downloadImageCommand =
      RxCommand.createSync((param) => param);
}
