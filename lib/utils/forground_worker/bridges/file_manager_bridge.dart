import 'package:yaga/managers/file_manager.dart';
import 'package:yaga/model/fetched_file.dart';
import 'package:yaga/utils/forground_worker/foreground_worker.dart';
import 'package:yaga/utils/forground_worker/messages/download_file_request.dart';
import 'package:yaga/utils/forground_worker/messages/image_update_msg.dart';

class FileManagerBridge {
  final FileManager _fileManager;
  final ForegroundWorker _worker;

  FileManagerBridge(this._fileManager, this._worker) {
    _worker.isolateResponseCommand
        .where((event) => event is ImageUpdateMsg)
        .map((event) => event as ImageUpdateMsg)
        .listen((msg) => _fileManager.updateImageCommand(msg.file));

    _worker.isolateResponseCommand
        .where((event) => event is FetchedFile)
        .map((event) => event as FetchedFile)
        .listen((event) => this._fileManager.fetchedFileCommand(event));

    _fileManager.downloadImageCommand.listen(
      (value) => _worker.sendRequest(DownloadFileRequest(value)),
    );
  }
}
