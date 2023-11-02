import 'package:rx_command/rx_command.dart';
import 'package:rxdart/rxdart.dart';
import 'package:yaga/managers/file_manager/file_manager.dart';
import 'package:yaga/managers/file_service_manager/media_file_manager.dart';
import 'package:yaga/utils/background_worker/background_worker.dart';
import 'package:yaga/utils/forground_worker/foreground_worker.dart';
import 'package:yaga/utils/forground_worker/messages/image_update_msg.dart';

import 'package:yaga/utils/forground_worker/messages/message.dart';

//todo: slowly deprecate bridges; this is logic which belongs into the fileManager
class FileManagerBridge {
  final FileManager _fileManager;
  final ForegroundWorker _worker;
  final MediaFileManager _mediaFileManager;
  final BackgroundWorker _backgroundWorker;

  FileManagerBridge(
    this._fileManager,
    this._worker,
    this._mediaFileManager,
    this._backgroundWorker,
  ) {
    _registerWorkerMessageWithTransformation(
      (ImageUpdateMsg msg) => msg.file,
      _fileManager.updateImageCommand,
    );
    _registerWorkerMessage(_fileManager.fetchedFileCommand);
    _registerWorkerMessage(_fileManager.filesActionDoneCommand);
    _registerWorkerMessage(_fileManager.updateFilesCommand);
    _registerWorkerMessage(_fileManager.fileUpdateMessage);

    _fileManager.fetchFileListCommand
        .where((event) => event.uri.scheme != _mediaFileManager.scheme)
        .listen((event) => _worker.sendRequest(event));

    _fileManager.sortFilesListCommand
        .listen((value) => _worker.sendRequest(value));
  }

  _registerWorkerMessageWithTransformation<T extends Message, P>(
      P Function(T) transformation, RxCommand<P, P> command) {
    _worker.isolateResponseCommand
        .mergeWith([_backgroundWorker.isolateResponseCommand])
        .where((event) => event is T)
        .map((event) => event as T)
        .map(transformation)
        .listen((msg) => command(msg));
  }

  _registerWorkerMessage<T extends Message>(RxCommand<T, T> command) {
    _registerWorkerMessageWithTransformation((T msg) => msg, command);
  }
}
