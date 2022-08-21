import 'package:yaga/managers/file_manager.dart';
import 'package:yaga/managers/global_settings_manager.dart';
import 'package:yaga/managers/media_file_manager.dart';
import 'package:yaga/model/fetched_file.dart';
import 'package:yaga/services/shared_preferences_service.dart';
import 'package:yaga/utils/background_worker/background_worker.dart';
import 'package:yaga/utils/forground_worker/foreground_worker.dart';
import 'package:yaga/utils/forground_worker/messages/file_list_message.dart';
import 'package:yaga/utils/forground_worker/messages/file_update_msg.dart';
import 'package:yaga/utils/forground_worker/messages/files_action/files_action_done.dart';
import 'package:yaga/utils/forground_worker/messages/image_update_msg.dart';
import 'package:yaga/utils/service_locator.dart';

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
    _worker.isolateResponseCommand
        .where((event) => event is ImageUpdateMsg)
        .map((event) => event as ImageUpdateMsg)
        .listen((msg) => _fileManager.updateImageCommand(msg.file));

    _worker.isolateResponseCommand
        .where((event) => event is FetchedFile)
        .map((event) => event as FetchedFile)
        .listen((event) => _fileManager.fetchedFileCommand(event));

    _backgroundWorker.isolateResponseCommand
        .listen((value) => _fileManager.fetchedFileCommand(value));

    _worker.isolateResponseCommand
        .where((event) => event is FileListMessage)
        .map((event) => event as FileListMessage)
        .listen((event) => _fileManager.updateFilesCommand(event));

    _worker.isolateResponseCommand
        .where((event) => event is FilesActionDone)
        .map((event) => event as FilesActionDone)
        .listen((event) => _fileManager.filesActionDoneCommand(event));

    _worker.isolateResponseCommand
        .where((event) => event is FileUpdateMsg)
        .map((event) => event as FileUpdateMsg)
        .listen((event) => _fileManager.fileUpdateMessage(event));

    _fileManager.downloadImageCommand.listen((request) async {
      final autoPersist =
          getIt.get<SharedPreferencesService>().loadPreferenceFromBool(
                GlobalSettingsManager.autoPersist,
              );

      if (request.forceDownload || autoPersist.value) {
        // in case persistence is active download in true background
        _backgroundWorker.downloadFile(request);
      } else {
        // otherwise download in foreground worker
        _worker.sendRequest(request);
      }
    });

    _fileManager.fetchFileListCommand
        .where((event) => event.uri.scheme != _mediaFileManager.scheme)
        .listen((event) => _worker.sendRequest(event));

    _fileManager.sortFilesListCommand
        .listen((value) => _worker.sendRequest(value));

    _fileManager.filesActionCommand
        .where((event) => event.sourceDir.scheme != _mediaFileManager.scheme)
        .listen((event) => _worker.sendRequest(event));
  }
}
