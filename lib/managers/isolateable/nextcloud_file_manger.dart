import 'dart:io';

import 'package:logger/logger.dart';
import 'package:rx_command/rx_command.dart';
import 'package:rxdart/rxdart.dart';
import 'package:yaga/managers/file_manager_base.dart';
import 'package:yaga/managers/file_sub_manager.dart';
import 'package:yaga/managers/isolateable/mapping_manager.dart';
import 'package:yaga/managers/isolateable/sync_manager.dart';
import 'package:yaga/model/nc_file.dart';
import 'package:yaga/services/isolateable/local_file_service.dart';
import 'package:yaga/services/isolateable/nextcloud_service.dart';
import 'package:yaga/utils/forground_worker/isolateable.dart';
import 'package:yaga/utils/logger.dart';
import 'package:yaga/utils/ncfile_stream_extensions.dart';

class NextcloudFileManager
    with Isolateable<NextcloudFileManager>
    implements FileSubManager {
  Logger _logger = getLogger(NextcloudFileManager);

  final NextCloudService _nextCloudService;
  final FileManagerBase _fileManager;
  final MappingManager _mappingManager;
  final SyncManager _syncManager;
  final LocalFileService _localFileService;

  RxCommand<NcFile, NcFile> _getPreviewCommand =
      RxCommand.createSync((param) => param);
  RxCommand<NcFile, NcFile> downloadPreviewCommand =
      RxCommand.createSync((param) => param);
  RxCommand<NcFile, NcFile> updatePreviewCommand =
      RxCommand.createSync((param) => param);

  NextcloudFileManager(
    this._fileManager,
    this._nextCloudService,
    this._localFileService,
    this._mappingManager,
    this._syncManager,
  ) {
    this._fileManager.registerFileManager(this);

    //todo: this has to be improved; currently asyncMap blocks for download + writing file to local storage; we need it to block only for download
    //todo: bug: this also tries to fetch previews for local files; no check if the file is local or remote
    _getPreviewCommand
        .asyncMap((ncFile) =>
            this._nextCloudService.getPreview(ncFile.uri).then((value) async {
              ncFile.previewFile = await _localFileService.createFile(
                  file: ncFile.previewFile,
                  bytes: value,
                  lastModified: ncFile.lastModified);
              return ncFile;
            }, onError: (err, stacktrace) {
              _logger.e(
                "Unexpected error while loading preview",
                err,
                stacktrace,
              );
              return null;
            }))
        .where((event) => event != null)
        .listen((value) => updatePreviewCommand(value));

    downloadPreviewCommand.listen((ncFile) {
      if (ncFile.previewFile != null && ncFile.previewFile.existsSync()) {
        updatePreviewCommand(ncFile);
        return;
      }
      this._getPreviewCommand(ncFile);
    });
  }

  @override
  String get scheme => _nextCloudService.scheme;

  @override
  Stream<NcFile> listFiles(
    Uri uri, {
    bool recursive = false,
  }) {
    //todo: add uri check
    return _syncManager.addUri(uri).asStream().flatMap((value) => Rx.merge([
          this._listLocalFileList(uri),
          this._listNextcloudFiles(uri, recursive),
        ]).doOnDone(() => this._finishSync(uri)));
  }

  @override
  Stream<List<NcFile>> listFileList(
    Uri uri, {
    bool recursive = false,
  }) {
    //todo: add uri check
    _logger.w("Listing... ($uri)");
    return _syncManager.addUri(uri).asStream().flatMap((_) => Rx.merge([
          this._listLocalFileList(uri),
          this._listNextcloudFiles(uri, recursive).collectToList(),
        ]).doOnData((event) {
          _logger.w("Emiting list! (${uri})");
        }).doOnDone(() => this._finishSync(uri)));
  }

  Stream<NcFile> _listNextcloudFiles(Uri uri, bool recursive) {
    return this
        ._listNextcloudFilesUpstream(uri)
        .recursively(recursive, this._listNextcloudFilesUpstream)
        .doOnData((file) => _syncManager.addRemoteFile(uri, file))
        .doOnError((err, stack) => _syncManager.removeUri(uri));
  }

  Stream<NcFile> _listNextcloudFilesUpstream(Uri uri) {
    return _nextCloudService.list(uri).asyncMap((file) async {
      if (!file.isDirectory) {
        file.localFile =
            File.fromUri(await _mappingManager.mapToLocalUri(file.uri));
        file.previewFile =
            File.fromUri(await _mappingManager.mapToTmpUri(file.uri));
      }
      return file;
    });
  }

  Stream<List<NcFile>> _listLocalFileList(Uri uri) {
    return Rx.merge([this._listTmpFiles(uri), this._listLocalFiles(uri)])
        .doOnData((file) => _syncManager.addFile(uri, file))
        .distinctUnique()
        .toList()
        .asStream();
  }

  Stream<NcFile> _listLocalFiles(Uri uri) {
    return this
        ._mappingManager
        .mapToLocalUri(uri)
        .asStream()
        .flatMap((value) => this._fileManager.listFiles(value))
        .asyncMap((file) async {
      file.uri = await _mappingManager.mapToRemoteUri(file.uri, uri);
      //todo: should this be a FileSystemEntity?
      // file.localFile = await _mappingManager.mapToLocalFile(file.uri);
      if (!file.isDirectory) {
        file.previewFile =
            File.fromUri(await _mappingManager.mapToTmpUri(file.uri));
      }
      return file;
    });
  }

  Stream<NcFile> _listTmpFiles(Uri uri) {
    return this
        ._mappingManager
        .mapToTmpUri(uri)
        .asStream()
        .flatMap((previewUri) => this._fileManager.listFiles(previewUri))
        .asyncMap((file) async {
      file.uri = await _mappingManager.mapTmpToRemoteUri(file.uri, uri);
      //todo: should this be a FileSystemEntity?
      if (!file.isDirectory) {
        file.previewFile = file.localFile;
        file.localFile =
            File.fromUri(await _mappingManager.mapToLocalUri(file.uri));
      }
      // file.previewFile = _localFileService.getTmpFile(file.uri.path);
      return file;
    });
  }

  Future _finishSync(Uri uri) {
    return _syncManager.syncUri(uri).then((files) => files.forEach(
          (file) => _deleteLocalFile(file),
        ));
  }

  void _deleteLocalFile(NcFile file) {
    _logger.w("Removing local file! (${file.uri.path})");
    this._localFileService.deleteFile(file.localFile);
    this._localFileService.deleteFile(file.previewFile);
    this._fileManager.updateFileList(file);
  }

  Future<void> deleteFiles(List<NcFile> files) {
    return Stream.fromIterable(files)
        .asyncMap((file) => this._nextCloudService.deleteFile(file))
        .forEach((file) => _deleteLocalFile(file));
  }
}
