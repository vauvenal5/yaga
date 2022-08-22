import 'dart:io';

import 'package:rx_command/rx_command.dart';
import 'package:rxdart/rxdart.dart';
import 'package:yaga/managers/file_manager_base.dart';
import 'package:yaga/managers/media_file_manager.dart';
import 'package:yaga/model/fetched_file.dart';
import 'package:yaga/model/nc_file.dart';
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

  FileManager(this._mediaFileManager) {
    registerFileManager(_mediaFileManager);

    fetchFileListCommand
        .where((event) => event.uri.scheme == _mediaFileManager.scheme)
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
        .listen((event) {
      _mediaFileManager.deleteFiles(event.files).then((files) {
        for (var file in files) {
          fileUpdateMessage(FileUpdateMsg("", file));
        }
      }).whenComplete(
        () => filesActionDoneCommand(FilesActionDone(event.key, event.sourceDir)),
      );
    });

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
  }

  Future<void> downloadFile(DownloadFileRequest request) async {
    final NcFile ncFile = request.file;

    // if file exists locally and download is not forced then load the local file
    if (!request.forceDownload &&
        ncFile.localFile != null &&
        await ncFile.localFile!.file.exists()) {
      ncFile.localFile!.exists = true;
      fetchedFileCommand(
        FetchedFile(
          ncFile,
          await (ncFile.localFile!.file as File).readAsBytes(),
        ),
      );
    } else {
      downloadImageCommand(request);
    }
  }
}
