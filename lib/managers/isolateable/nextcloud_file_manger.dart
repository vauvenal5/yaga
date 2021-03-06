import 'dart:io';

import 'package:rx_command/rx_command.dart';
import 'package:rxdart/rxdart.dart';
import 'package:yaga/managers/file_manager_base.dart';
import 'package:yaga/managers/file_sub_manager.dart';
import 'package:yaga/managers/isolateable/mapping_manager.dart';
import 'package:yaga/managers/isolateable/sync_manager.dart';
import 'package:yaga/model/local_file.dart';
import 'package:yaga/model/nc_file.dart';
import 'package:yaga/model/preview_fetch_meta.dart';
import 'package:yaga/services/isolateable/local_file_service.dart';
import 'package:yaga/services/isolateable/nextcloud_service.dart';
import 'package:yaga/utils/forground_worker/isolateable.dart';
import 'package:yaga/utils/logger.dart';
import 'package:yaga/utils/ncfile_stream_extensions.dart';

class NextcloudFileManager
    with Isolateable<NextcloudFileManager>
    implements FileSubManager {
  final _logger = YagaLogger.getLogger(NextcloudFileManager);

  final NextCloudService _nextCloudService;
  final FileManagerBase _fileManager;
  final MappingManager _mappingManager;
  final SyncManager _syncManager;
  final LocalFileService _localFileService;

  RxCommand<NcFile, NcFile> _getPreviewCommand =
      RxCommand.createSync((param) => param);
  RxCommand<int, int> _readyForNextPreviewRequest =
      RxCommand.createSync((param) => param);

  RxCommand<NcFile, NcFile> downloadPreviewCommand =
      RxCommand.createSync((param) => param);
  RxCommand<NcFile, NcFile> updatePreviewCommand =
      RxCommand.createSync((param) => param);
  RxCommand<NcFile, NcFile> downloadPreviewFaildCommand =
      RxCommand.createSync((param) => param);

  NextcloudFileManager(
    this._fileManager,
    this._nextCloudService,
    this._localFileService,
    this._mappingManager,
    this._syncManager,
  ) {
    this._fileManager.registerFileManager(this);

    _getPreviewCommand
        .zipWith(
          // this stream is managing the amount of allowed parallel downloads of previews (currently 10)
          _readyForNextPreviewRequest.doOnData(
            (event) => _logger.info("Arming preview index: $event"),
          ),
          (ncFile, number) => PreviewFetchMeta(ncFile, number),
        )
        .doOnData(
          (event) => _logger.info(
            "Fetching preview index: ${event.fetchIndex}",
          ),
        )
        // debounce requests which have been added multiple times due to scrolling
        .where((ncFileMeta) {
          if (ncFileMeta.file.previewFile.file.existsSync()) {
            _logger.info("Preview exists index: ${ncFileMeta.fetchIndex}");
            _readyForNextPreviewRequest(ncFileMeta.fetchIndex);
            return false;
          }
          return true;
        })
        .flatMap(
          (ncFileMeta) => Stream.fromFuture(
            this._nextCloudService.getPreview(ncFileMeta.file.uri).then(
              (value) async {
                ncFileMeta.file.previewFile.file =
                    await _localFileService.createFile(
                        file: ncFileMeta.file.previewFile.file,
                        bytes: value,
                        lastModified: ncFileMeta.file.lastModified);
                ncFileMeta.file.previewFile.exists = true;
                _logger.info("Preview fetched index: ${ncFileMeta.fetchIndex}");
                _logger.fine("Preview fetched: (${ncFileMeta.file.uri})");
                return ncFileMeta;
              },
              //todo: do we really need both error handlers
              onError: (err, stacktrace) {
                _logger.warning(
                  "Preview fetching failed, index: ${ncFileMeta.fetchIndex}",
                );
                _logger.severe(
                  "Unexpected error while loading preview",
                  err,
                  stacktrace,
                );
                downloadPreviewFaildCommand(ncFileMeta.file);
                return PreviewFetchMeta(null, ncFileMeta.fetchIndex);
              },
            ),
          ),
        )
        .doOnData((event) => _readyForNextPreviewRequest(event.fetchIndex))
        .where((event) => event.file != null)
        .listen(
          (ncFileMeta) => updatePreviewCommand(ncFileMeta.file),
          onError: (error, stacktrace) {
            int index = (_readyForNextPreviewRequest.lastResult + 1) % 10;

            _logger.warning("Error on stream. Reintroducing index: $index");
            _readyForNextPreviewRequest(index);

            _logger.severe(
              "Unexpected error in preview stream",
              error,
              stacktrace,
            );
          },
        );

    //init preview stream for 10 simultanious requests
    RangeStream(1, 10).listen((event) => _readyForNextPreviewRequest(event));

    downloadPreviewCommand.listen((ncFile) {
      if (ncFile.previewFile != null && ncFile.previewFile.file.existsSync()) {
        ncFile.previewFile.exists = true;
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
          this._listLocalFileList(uri, recursive),
          this._listNextcloudFiles(uri, recursive),
        ]).doOnDone(() => this._finishSync(uri)));
  }

  @override
  Stream<List<NcFile>> listFileList(
    Uri uri, {
    bool recursive = false,
  }) {
    //todo: add uri check
    _logger.finer("Listing... ($uri)");
    return _syncManager.addUri(uri).asStream().flatMap((_) => Rx.merge([
          this._listLocalFileList(uri, recursive),
          this._listNextcloudFiles(uri, recursive).collectToList(),
        ]).doOnData((event) {
          _logger.finer("Emiting list! (${uri})");
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
        file.localFile = await _createLocalFile(file.uri);
        file.previewFile = await _createTmpFile(file.uri);
      }
      return file;
    });
  }

  Stream<List<NcFile>> _listLocalFileList(Uri uri, bool recursive) {
    return Rx.merge([
      this._listTmpFiles(uri, recursive),
      this._listLocalFiles(uri, recursive),
    ])
        .doOnData((file) => _syncManager.addFile(uri, file))
        .distinctUnique()
        .toList()
        .asStream();
  }

  Stream<NcFile> _listLocalFiles(Uri uri, bool recursive) =>
      _listFromLocalFileManager(
        uri,
        recursive,
        this._mappingManager.mapToLocalUri,
        (file) async {
          file.uri = await _mappingManager.mapToRemoteUri(file.uri, uri);
          //todo: should this be a FileSystemEntity?
          // file.localFile = await _mappingManager.mapToLocalFile(file.uri);
          if (!file.isDirectory) {
            file.previewFile = await _createTmpFile(file.uri);
          }
          return file;
        },
      );

  Stream<NcFile> _listTmpFiles(Uri uri, bool recursive) =>
      _listFromLocalFileManager(
        uri,
        recursive,
        this._mappingManager.mapToTmpUri,
        (file) async {
          file.uri = await _mappingManager.mapTmpToRemoteUri(file.uri, uri);
          //todo: should this be a FileSystemEntity?
          if (!file.isDirectory) {
            file.previewFile = file.localFile;
            file.localFile = await _createLocalFile(file.uri);
          }
          // file.previewFile = _localFileService.getTmpFile(file.uri.path);
          return file;
        },
      );

  Stream<NcFile> _listFromLocalFileManager(
      Uri uri,
      bool recursive,
      Future<Uri> Function(Uri) mappingCall,
      Future<NcFile> Function(NcFile) resultMapping) {
    return mappingCall(uri)
        .asStream()
        .flatMap(
            (value) => this._fileManager.listFiles(value, recursive: recursive))
        .asyncMap(resultMapping);
  }

  Future _finishSync(Uri uri) {
    return _syncManager.syncUri(uri).then(
          (files) => files.forEach(
            (file) async {
              if (await this._mappingManager.isSyncDelete(file.uri)) {
                _deleteLocalFile(file);
              } else {
                this._fileManager.updateFileList(file);
              }
            },
          ),
        );
  }

  Future<NcFile> _deleteLocalFile(NcFile file) async {
    _logger.warning("Removing local file! (${file.uri.path})");
    this._localFileService.deleteFile(file.localFile.file);
    this._localFileService.deleteFile(file.previewFile.file);
    this._fileManager.updateFileList(file);
    return file;
  }

  @override
  Future<NcFile> deleteFile(NcFile file, bool local) async {
    if (local) {
      this._localFileService.deleteFile(file.localFile.file);
      file.localFile.exists = false;
      this._fileManager.updateImageCommand(file);
      return file;
    }

    return this
        ._nextCloudService
        .deleteFile(file)
        .then((value) => _deleteLocalFile(file));
  }

  @override
  Future<NcFile> copyFile(NcFile file, Uri destination, bool overwrite) =>
      this._nextCloudService.copyFile(file, destination, overwrite);

  @override
  Future<NcFile> moveFile(NcFile file, Uri destination, bool overwrite) =>
      this._nextCloudService.moveFile(file, destination, overwrite);

  Future<LocalFile> _createLocalFile(Uri uri) async {
    final file = LocalFile(
      File.fromUri(await _mappingManager.mapToLocalUri(uri)),
    );
    file.exists = file.file.existsSync();
    return file;
  }

  Future<LocalFile> _createTmpFile(Uri uri) async {
    final file = LocalFile(
      File.fromUri(await _mappingManager.mapToTmpUri(uri)),
    );
    file.exists = file.file.existsSync();
    return file;
  }
}
