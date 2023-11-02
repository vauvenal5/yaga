import 'package:rxdart/rxdart.dart';
import 'package:yaga/managers/file_manager/file_manager.dart';
import 'package:yaga/managers/file_service_manager/media_file_manager.dart';
import 'package:yaga/model/fetched_file.dart';
import 'package:yaga/utils/background_worker/background_worker.dart';
import 'package:yaga/utils/forground_worker/foreground_worker.dart';
import 'package:yaga/utils/forground_worker/messages/file_list_message.dart';
import 'package:yaga/utils/forground_worker/messages/file_update_msg.dart';
import 'package:yaga/utils/forground_worker/messages/files_action/files_action_done.dart';
import 'package:yaga/utils/forground_worker/messages/image_update_msg.dart';

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
    _backgroundWorker.isolateResponseCommand
        .where((event) => event is ImageUpdateMsg)
        .map((event) => event as ImageUpdateMsg)
        .listen((msg) => _fileManager.updateImageCommand(msg.file));

    _worker.isolateResponseCommand
        .mergeWith([_backgroundWorker.isolateResponseCommand])
        .where((event) => event is FetchedFile)
        .map((event) => event as FetchedFile)
        .listen((event) => _fileManager.fetchedFileCommand(event));

    _worker.isolateResponseCommand
        .where((event) => event is FileListMessage)
        .map((event) => event as FileListMessage)
        .listen((event) => _fileManager.updateFilesCommand(event));

    _worker.isolateResponseCommand
        .mergeWith([_backgroundWorker.isolateResponseCommand])
        .where((event) => event is FilesActionDone)
        .map((event) => event as FilesActionDone)
        .listen((event) => _fileManager.filesActionDoneCommand(event));

    _backgroundWorker.isolateResponseCommand
        .where((event) => event is FileUpdateMsg)
        .map((event) => event as FileUpdateMsg)
        .listen((event) => _fileManager.fileUpdateMessage(event));

    _fileManager.fetchFileListCommand
        .where((event) => event.uri.scheme != _mediaFileManager.scheme)
        .listen((event) => _worker.sendRequest(event));

    _fileManager.sortFilesListCommand
        .listen((value) => _worker.sendRequest(value));
  }
}
