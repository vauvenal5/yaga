import 'package:yaga/managers/file_manager.dart';
import 'package:yaga/managers/media_file_manager.dart';
import 'package:yaga/model/fetched_file.dart';
import 'package:yaga/utils/forground_worker/foreground_worker.dart';
import 'package:yaga/utils/forground_worker/messages/file_list_message.dart';
import 'package:yaga/utils/forground_worker/messages/image_update_msg.dart';

class FileManagerBridge {
  final FileManager _fileManager;
  final ForegroundWorker _worker;
  final MediaFileManager _mediaFileManager;

  FileManagerBridge(this._fileManager, this._worker, this._mediaFileManager) {
    _worker.isolateResponseCommand
        .where((event) => event is ImageUpdateMsg)
        .map((event) => event as ImageUpdateMsg)
        .listen((msg) => _fileManager.updateImageCommand(msg.file));

    _worker.isolateResponseCommand
        .where((event) => event is FetchedFile)
        .map((event) => event as FetchedFile)
        .listen((event) => _fileManager.fetchedFileCommand(event));

    _worker.isolateResponseCommand
        .where((event) => event is FileListMessage)
        .map((event) => event as FileListMessage)
        .listen((event) => _fileManager.updateFilesCommand(event));

    _fileManager.downloadImageCommand.listen(
      (value) => _worker.sendRequest(value),
    );

    _fileManager.fetchFileListCommand
      .where((event) => event.uri.scheme != _mediaFileManager.scheme)
      .listen((event) => _worker.sendRequest(event));

    _fileManager.sortFilesListCommand.listen((value) => _worker.sendRequest(value));
  }
}
