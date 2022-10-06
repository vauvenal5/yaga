import 'dart:io';

import 'package:rx_command/rx_command.dart';
import 'package:rxdart/rxdart.dart';
import 'package:yaga/managers/file_manager_base.dart';
import 'package:yaga/managers/isolateable/mapping_manager.dart';
import 'package:yaga/managers/file_manager/isolateable/nextcloud_background_file_manager.dart';
import 'package:yaga/managers/isolateable/sync_manager.dart';
import 'package:yaga/model/local_file.dart';
import 'package:yaga/model/nc_file.dart';
import 'package:yaga/model/preview_fetch_meta.dart';
import 'package:yaga/services/isolateable/local_file_service.dart';
import 'package:yaga/services/isolateable/nextcloud_service.dart';
import 'package:yaga/utils/forground_worker/isolateable.dart';
import 'package:yaga/utils/logger.dart';
import 'package:yaga/utils/ncfile_stream_extensions.dart';

class NextcloudFileManager extends NextcloudBackgroundFileManager
    with Isolateable<NextcloudFileManager> {
  final _logger = YagaLogger.getLogger(NextcloudFileManager);

  final MappingManager _mappingManager;
  final SyncManager _syncManager;

  final RxCommand<NcFile, NcFile> _getPreviewCommand =
      RxCommand.createSync((param) => param);
  final RxCommand<int, int> _readyForNextPreviewRequest =
      RxCommand.createSync((param) => param);

  final RxCommand<NcFile, NcFile> downloadPreviewCommand =
      RxCommand.createSync((param) => param);
  final RxCommand<NcFile, NcFile> updatePreviewCommand =
      RxCommand.createSync((param) => param);
  final RxCommand<NcFile, NcFile> downloadPreviewFaildCommand =
      RxCommand.createSync((param) => param);

  NextcloudFileManager(
    FileManagerBase fileManager,
    NextCloudService nextCloudService,
    LocalFileService localFileService,
    this._mappingManager,
    this._syncManager,
  ) : super(nextCloudService, localFileService, fileManager){
    fileManager.registerFileManager(this);

    _getPreviewCommand
        .zipWith(
          // this stream is managing the amount of allowed parallel downloads of previews (currently 10)
          _readyForNextPreviewRequest.doOnData(
            (event) => _logger.info("Arming preview index: $event"),
          ),
          (ncFile, int number) => PreviewFetchMeta(ncFile, number),
        )
        .doOnData(
          (event) => _logger.info(
            "Fetching preview index: ${event.fetchIndex}",
          ),
        )
        // debounce requests which have been added multiple times due to scrolling
        .where((ncFileMeta) {
          if (ncFileMeta.file.previewFile!.file.existsSync()) {
            _logger.info("Preview exists index: ${ncFileMeta.fetchIndex}");
            _readyForNextPreviewRequest(ncFileMeta.fetchIndex);
            return false;
          }
          return true;
        })
        .flatMap(
          (ncFileMeta) => Stream.fromFuture(
            nextCloudService.getPreview(ncFileMeta.file.uri).then(
              (value) async {
                ncFileMeta.file.previewFile!.file =
                    await localFileService.createFile(
                        file: ncFileMeta.file.previewFile!.file as File,
                        bytes: value,
                        lastModified: ncFileMeta.file.lastModified);
                ncFileMeta.file.previewFile!.exists = true;
                _logger.info("Preview fetched index: ${ncFileMeta.fetchIndex}");
                _logger.fine("Preview fetched: (${ncFileMeta.file.uri})");
                return ncFileMeta;
              },
              //todo: do we really need both error handlers
              onError: (err, StackTrace stacktrace) {
                _logger.warning(
                  "Preview fetching failed, index: ${ncFileMeta.fetchIndex}",
                );
                _logger.severe(
                  "Unexpected error while loading preview",
                  err,
                  stacktrace,
                );
                downloadPreviewFaildCommand(ncFileMeta.file);
                return PreviewFetchMeta(ncFileMeta.file, ncFileMeta.fetchIndex,
                    success: false);
              },
            ),
          ),
        )
        .doOnData((event) => _readyForNextPreviewRequest(event.fetchIndex))
        .where((event) => event.success)
        .listen(
          (ncFileMeta) => updatePreviewCommand(ncFileMeta.file),
          onError: (error, StackTrace stacktrace) {
            final int index = (_readyForNextPreviewRequest.lastResult! + 1) % 10;

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
      if (ncFile.previewFile != null && ncFile.previewFile!.file.existsSync()) {
        ncFile.previewFile!.exists = true;
        updatePreviewCommand(ncFile);
        return;
      }
      _getPreviewCommand(ncFile);
    });
  }

  @override
  String get scheme => nextCloudService.scheme;

  @override
  Stream<NcFile> listFiles(
    Uri uri, {
    bool recursive = false,
  }) {
    //todo: add uri check
    return _syncManager.addUri(uri).asStream().flatMap((value) => Rx.merge([
          _listLocalFileList(uri, recursive),
          _listNextcloudFiles(uri, recursive),
        ]).doOnDone(() => _finishSync(uri))) as Stream<NcFile>;
  }

  @override
  Stream<List<NcFile>> listFileList(
    Uri uri, {
    bool recursive = false,
  }) {
    //todo: add uri check
    _logger.finer("Listing... ($uri)");
    return _syncManager.addUri(uri).asStream().flatMap((_) => Rx.merge([
          _listLocalFileList(uri, recursive),
          _listNextcloudFiles(uri, recursive).collectToList(),
        ]).doOnData((event) {
          _logger.finer("Emiting list! ($uri)");
        }).doOnDone(() => _finishSync(uri)));
  }

  Stream<NcFile> _listNextcloudFiles(Uri uri, bool recursive) {
    return _listNextcloudFilesUpstream(uri)
        .recursively(_listNextcloudFilesUpstream, recursive: recursive)
        .doOnData((file) => _syncManager.addRemoteFile(uri, file))
        .doOnError((err, stack) => _syncManager.removeUri(uri));
  }

  Stream<NcFile> _listNextcloudFilesUpstream(Uri uri) {
    return nextCloudService.list(uri).asyncMap((file) async {
      if (!file.isDirectory) {
        file.localFile = await _createLocalFile(file.uri);
        file.previewFile = await _createTmpFile(file.uri);
      }
      return file;
    });
  }

  Stream<List<NcFile>> _listLocalFileList(Uri uri, bool recursive) {
    return Rx.merge([
      _listTmpFiles(uri, recursive),
      _listLocalFiles(uri, recursive),
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
        _mappingManager.mapToLocalUri,
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
        _mappingManager.mapToTmpUri,
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
        .flatMap((value) => fileManager.listFiles(value, recursive: recursive))
        .asyncMap(resultMapping);
  }

  Future _finishSync(Uri uri) {
    return _syncManager.syncUri(uri).then((files) async {
      for (final NcFile file in files) {
        if (await _mappingManager.isSyncDelete(file.uri)) {
          deleteLocalFile(file);
        } else {
          fileManager.updateFileList(file);
        }
      }
    });
  }

  Future<LocalFile> _createLocalFile(Uri uri) async {
    File file = File.fromUri(await _mappingManager.mapToLocalUri(uri));
    return LocalFile(file, file.existsSync());
  }

  Future<LocalFile> _createTmpFile(Uri uri) async {
    File file = File.fromUri(await _mappingManager.mapToTmpUri(uri));
    return LocalFile(file, file.existsSync());
  }
}
