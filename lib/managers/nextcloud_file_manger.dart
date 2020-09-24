import 'dart:io';

import 'package:logger/logger.dart';
import 'package:rx_command/rx_command.dart';
import 'package:rxdart/rxdart.dart';
import 'package:yaga/managers/file_manager.dart';
import 'package:yaga/managers/file_sub_manager.dart';
import 'package:yaga/managers/local_file_manager.dart';
import 'package:yaga/managers/mapping_manager.dart';
import 'package:yaga/managers/sync_manager.dart';
import 'package:yaga/model/nc_file.dart';
import 'package:yaga/services/local_file_service.dart';
import 'package:yaga/services/nextcloud_service.dart';
import 'package:yaga/utils/logger.dart';

class NextcloudFileManager implements FileSubManager {
  Logger _logger = getLogger(NextcloudFileManager);

  final NextCloudService _nextCloudService;
  final FileManager _fileManager;
  final MappingManager _mappingManager;
  final SyncManager _syncManager;
  final LocalFileService _localFileService;

  NextcloudFileManager(
    this._fileManager,
    this._nextCloudService, 
    this._localFileService, 
    this._mappingManager, 
    this._syncManager,
  );

  Future<NextcloudFileManager> init() async {
    this._fileManager.registerFileManager(this);
    return this;
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
    return _syncManager.addUri(uri).asStream().flatMap((value) => Rx.merge([
        this._listTmpFiles(uri)
          .doOnData((file) => _syncManager.addFile(uri, file))
          .toList().asStream(),
        this._listLocalFiles(uri)
          .doOnData((file) => _syncManager.addFile(uri, file))
          .toList().asStream(),
        this._listNextcloudFiles(uri)
        .doOnData((file) => _syncManager.addRemoteFile(uri, file))
        .doOnError((err, stack) {
          _syncManager.removeUri(uri);
        })
        .toList()
        .asStream()
        .flatMap((list) {
          if(!recursive) {
            return Stream.value(list);
          }

          return Rx.merge([
            Stream.value(list),
            Stream.fromIterable(list)
            .where((file) => file.isDirectory)
            .flatMap((file) => this.listFileList(file.uri, recursive: recursive))
          ]);
        })
      ])
      .doOnDone(() => _syncManager.syncUri(uri).then((value) => value.forEach((element) {
        _logger.w("Removing local file! (${element.uri.path})");
        this._fileManager.updateFileList(element);
        //todo: syncManager does not guarantee that files are set
        this._localFileService.deleteFile(element.localFile);
        this._localFileService.deleteFile(element.previewFile);
      })))
    );
  }
}