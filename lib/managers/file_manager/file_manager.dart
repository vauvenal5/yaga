import 'dart:io';

import 'package:rx_command/rx_command.dart';
import 'package:rxdart/rxdart.dart';
import 'package:yaga/managers/file_manager/file_manager_base.dart';
import 'package:yaga/managers/file_service_manager/media_file_manager.dart';
import 'package:yaga/managers/global_settings_manager.dart';
import 'package:yaga/model/fetched_file.dart';
import 'package:yaga/model/nc_file.dart';
import 'package:yaga/services/shared_preferences_service.dart';
import 'package:yaga/utils/background_worker/background_worker.dart';
import 'package:yaga/utils/forground_worker/foreground_worker.dart';
import 'package:yaga/utils/forground_worker/messages/download_file_request.dart';
import 'package:yaga/utils/forground_worker/messages/file_list_request.dart';
import 'package:yaga/utils/forground_worker/messages/file_update_msg.dart';
import 'package:yaga/utils/forground_worker/messages/files_action/delete_files_request.dart';
import 'package:yaga/utils/forground_worker/messages/files_action/files_action_done.dart';
import 'package:yaga/utils/forground_worker/messages/files_action/files_action_request.dart';
import 'package:yaga/utils/forground_worker/messages/sort_request.dart';
import 'package:yaga/utils/ncfile_stream_extensions.dart';

class FileManager extends FileManagerBase {
  RxCommand<DownloadFileRequest, DownloadFileRequest> downloadImageCommand =
      RxCommand.createSync((param) => param);

  RxCommand<FileListRequest, FileListRequest> fetchFileListCommand =
      RxCommand.createSync((param) => param);

  RxCommand<SortRequest, SortRequest> sortFilesListCommand =
      RxCommand.createSync((param) => param);

  RxCommand<FilesActionRequest, FilesActionRequest> filesActionCommand =
      RxCommand.createSync((param) => param);
  RxCommand<FilesActionDone, FilesActionDone> filesActionDoneCommand =
      RxCommand.createSync((param) => param);

  RxCommand<FileUpdateMsg, FileUpdateMsg> fileUpdateMessage =
      RxCommand.createSync((param) => param);

  final MediaFileManager _mediaFileManager;
  final SharedPreferencesService _sharedPreferencesService;
  final ForegroundWorker _foregroundWorker;
  final BackgroundWorker _backgroundWorker;

  FileManager(
    this._mediaFileManager,
    this._sharedPreferencesService,
    this._foregroundWorker,
    this._backgroundWorker,
  ) {
    registerFileManager(_mediaFileManager);

    fetchFileListCommand
        .where((event) => _mediaFileManager.isRelevant(event.uri.scheme))
        .flatMap(
          (value) => _mediaFileManager
              .listFiles(value.uri)
              .collectToList()
              .map((event) => SortRequest(value.key, event, value)),
        )
        .listen((event) {
      sortFilesListCommand(event);
    });

    filesActionCommand
        .where((event) => event is DeleteFilesRequest)
        .map((event) => event as DeleteFilesRequest)
        .where((event) => event.sourceDir.scheme == _mediaFileManager.scheme)
        .listen(_handleLocalDeleteRequest);

    filesActionCommand
        .where((event) => event.sourceDir.scheme != _mediaFileManager.scheme)
        .listen(_handleFilesAction);

    //todo: re-enable when copy/move support is added
    // fileActionCommand
    //     .where((event) => event is DestinationActionFilesRequest)
    //     .map((event) => event as DestinationActionFilesRequest)
    //     .listen((event) {
    //       if(event.action == DestinationAction.copy) {
    //         _mediaFileManager.copyFile(event.files.first, event.destination);
    //       } else {
    //         _mediaFileManager.moveFile(event.files.first, event.destination);
    //       }
    // });

    downloadImageCommand.listen(_handleDownload);
  }

  @override
  Stream<NcFile> listFiles(Uri uri, {bool recursive = false}) {
    // not supported in UI branch because to computational intensive
    throw UnimplementedError();
  }

  void _handleLocalDeleteRequest(DeleteFilesRequest request) async {
    _mediaFileManager.deleteFiles(request.files).then((files) {
      for (var file in files) {
        fileUpdateMessage(FileUpdateMsg("", file));
      }
    }).whenComplete(
      () => filesActionDoneCommand(
          FilesActionDone(request.key, request.sourceDir)),
    );
  }

  void _handleFilesAction(FilesActionRequest request) async {
    final useBackground = _sharedPreferencesService
        .loadPreferenceFromBool(
          GlobalSettingsManager.useBackground,
        )
        .value;

    useBackground
        ? _backgroundWorker.sendRequest(request)
        : _foregroundWorker.sendRequest(request);
  }

  void _handleDownload(DownloadFileRequest request) async {
    final NcFile ncFile = request.file;

    // if file exists locally and download is not forced then load the local file
    if (!request.forceDownload &&
        ncFile.localFile != null &&
        await ncFile.localFile!.file.exists()) {
      ncFile.localFile!.exists = true;
      //todo: why are we directly reading the file in here and not in the service?
      fetchedFileCommand(
        FetchedFile(
          ncFile,
          await (ncFile.localFile!.file as File).readAsBytes(),
        ),
      );
      return;
    }

    final autoPersist = _sharedPreferencesService
        .loadPreferenceFromBool(
          GlobalSettingsManager.autoPersist,
        )
        .value;

    final useBackground = _sharedPreferencesService
        .loadPreferenceFromBool(
          GlobalSettingsManager.useBackground,
        )
        .value;

    request.persist = request.forceDownload || autoPersist;

    if (useBackground && request.persist) {
      // in case persistence is active download in true background
      _backgroundWorker.sendRequest(request);
    } else {
      // otherwise download in foreground worker
      _foregroundWorker.sendRequest(request);
    }
  }
}
