import 'dart:io';

import 'package:logger/logger.dart';
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

class NextcloudFileManager with Isolateable<NextcloudFileManager> implements FileSubManager {
  Logger _logger = getLogger(NextcloudFileManager);

  final NextCloudService _nextCloudService;
  final FileManagerBase _fileManager;
  final MappingManager _mappingManager;
  final SyncManager _syncManager;
  final LocalFileService _localFileService;

  NextcloudFileManager(
    this._fileManager,
    this._nextCloudService, 
    this._localFileService, 
    this._mappingManager, 
    this._syncManager,
  ) {
    this._fileManager.registerFileManager(this);
  }

  @override
  String get scheme => _nextCloudService.scheme;

  @override
  Stream<NcFile> listFiles(Uri uri) {
    //todo: add uri check
    return _syncManager.addUri(uri).asStream().flatMap((value) => Rx.merge([
        this._listTmpFiles(uri),
        this._listLocalFiles(uri),
        this._listNextcloudFiles(uri)
        .doOnData((file) => _syncManager.addRemoteFile(uri, file))
        .doOnError((err, stack) {
          _syncManager.removeUri(uri);
        })
      ])
      .doOnData((file) => _syncManager.addFile(uri, file))
      .doOnDone(() => _syncManager.syncUri(uri).then((value) => value.forEach((element) {
        _logger.w("Removing local file! (${element.uri.path})");
        this._fileManager.updateFileList(element);
        //todo: syncManager does not guarantee that files are set
        this._localFileService.deleteFile(element.localFile);
        this._localFileService.deleteFile(element.previewFile);
      }))));
  }

  Stream<NcFile> _listNextcloudFiles(Uri uri) {
    return _nextCloudService.list(uri).asyncMap((file) async {
      if(!file.isDirectory) {
        file.localFile = File.fromUri(await _mappingManager.mapToLocalUri(file.uri));
        file.previewFile = File.fromUri(await _mappingManager.mapToTmpUri(file.uri));
      }
      return file;
    });
  }

  Stream<NcFile> _listLocalFiles(Uri uri) {
    return this._mappingManager.mapToLocalUri(uri).asStream()
      .flatMap((value) => this._fileManager.listFiles(value))
      .asyncMap((file) async {
        file.uri = await _mappingManager.mapToRemoteUri(file.uri, uri);
        //todo: should this be a FileSystemEntity?
        // file.localFile = await _mappingManager.mapToLocalFile(file.uri);
        if(!file.isDirectory) {
          file.previewFile = File.fromUri(await _mappingManager.mapToTmpUri(file.uri));
        }
        return file;
      });
  }

  Stream<NcFile> _listTmpFiles(Uri uri) {
    return this._mappingManager.mapToTmpUri(uri).asStream()
      .flatMap((previewUri) => this._fileManager.listFiles(previewUri))
      .asyncMap((file) async {
        file.uri = await _mappingManager.mapTmpToRemoteUri(file.uri, uri);
        //todo: should this be a FileSystemEntity?
        if(!file.isDirectory) {
          file.previewFile = file.localFile;
          file.localFile = File.fromUri(await _mappingManager.mapToLocalUri(file.uri));
        }
        // file.previewFile = _localFileService.getTmpFile(file.uri.path);
        return file;
      });
  }

  @override
  Stream<List<NcFile>> listFileList(Uri uri, {bool recursive = false}) {
    //todo: add uri check
    _logger.d("Listing... $uri");
    return _syncManager.addUri(uri).asStream().flatMap((_) => Rx.merge([
        this._listLocalFileList(uri),
        this._listNextcloudFiles(uri)
        .doOnData((file) => _syncManager.addRemoteFile(uri, file))
        .doOnError((err, stack) {
          _syncManager.removeUri(uri);
        })
        .toList()
        .asStream()
        .onErrorReturn([])
        .flatMap((list) {
          if(!recursive) {
            return Stream.value(list);
          }

          return Rx.merge([
            Stream.value(list),
            Stream.fromIterable(list)
            .where((file) => file.isDirectory)
            .doOnData((file) => _logger.d("Emiting from recursive. (${file.uri.path})"))
            .flatMap((file) => this.listFileList(file.uri, recursive: recursive))
          ]);
        })
      ])
      .doOnData((event) {_logger.w("Emiting list! (${uri})");})
      .doOnDone(() => _syncManager.syncUri(uri).then((value) => value.forEach((element) {
        _logger.w("Removing local file! (${element.uri.path})");
        this._fileManager.updateFileList(element);
        //todo: syncManager does not guarantee that files are set
        this._localFileService.deleteFile(element.localFile);
        this._localFileService.deleteFile(element.previewFile);
      })))
    );
  }

  Stream<List<NcFile>> _listLocalFileList(Uri uri) {
    return Rx.merge([
      this._listTmpFiles(uri),
      this._listLocalFiles(uri)
    ])
    .doOnData((file) => _syncManager.addFile(uri, file))
    .distinctUnique()
    .toList()
    .asStream();
  }
}