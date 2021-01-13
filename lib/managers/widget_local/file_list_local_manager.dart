import 'dart:async';

import 'package:logger/logger.dart';
import 'package:rx_command/rx_command.dart';
import 'package:uuid/uuid.dart';
import 'package:yaga/managers/file_manager.dart';
import 'package:yaga/managers/isolateable/mapping_manager.dart';
import 'package:yaga/managers/settings_manager.dart';
import 'package:yaga/model/nc_file.dart';
import 'package:yaga/model/preferences/bool_preference.dart';
import 'package:yaga/model/preferences/mapping_preference.dart';
import 'package:yaga/services/isolateable/local_file_service.dart';
import 'package:yaga/utils/forground_worker/foreground_worker.dart';
import 'package:yaga/utils/forground_worker/messages/delete_files_done.dart';
import 'package:yaga/utils/forground_worker/messages/delete_files_request.dart';
import 'package:yaga/utils/forground_worker/messages/file_list_done.dart';
import 'package:yaga/utils/forground_worker/messages/file_list_message.dart';
import 'package:yaga/utils/forground_worker/messages/file_list_request.dart';
import 'package:yaga/utils/forground_worker/messages/file_list_response.dart';
import 'package:yaga/utils/forground_worker/messages/file_update_msg.dart';
import 'package:yaga/utils/forground_worker/messages/message.dart';
import 'package:yaga/utils/logger.dart';
import 'package:yaga/utils/service_locator.dart';

// this is a widget local manager, meaning that it is intendet to exist per widget that needs its functionality
// however this also means that the owning widget has to manage init and disposal
// treat it like local state
class FileListLocalManager {
  Logger _logger = getLogger(FileListLocalManager);
  List<NcFile> files = List();
  BoolPreference recursive;
  List<NcFile> selected = List();

  RxCommand<bool, bool> loadingChangedCommand;
  RxCommand<List<NcFile>, List<NcFile>> filesChangedCommand;
  RxCommand<NcFile, NcFile> selectFileCommand =
      RxCommand.createSync((param) => param);
  RxCommand<bool, bool> selectionModeChanged =
      RxCommand.createSync((param) => param, initialLastResult: false);

  StreamSubscription<MappingPreference>
      _updatedMappingPreferenceCommandSubscription;
  StreamSubscription<FileUpdateMsg> _updateFileListSubscripton;
  StreamSubscription<BoolPreference> _updateRecursiveSubscription;

  ForegroundWorker _worker;
  StreamSubscription<Message> _foregroundMessageCommandSubscription;

  Uuid uuid = Uuid();

  Uri _uri;
  String managerKey;

  bool get isInSelectionMode => this.selected.length > 0;

  FileListLocalManager(this._uri, this.recursive) {
    _worker = getIt.get<ForegroundWorker>();
    loadingChangedCommand =
        RxCommand.createSync((param) => param, initialLastResult: false);
    filesChangedCommand =
        RxCommand.createSync((param) => param, initialLastResult: []);
    managerKey = uuid.v1();
  }

  Uri get uri => this._uri;

  void dispose() {
    this._foregroundMessageCommandSubscription?.cancel();
    this._updatedMappingPreferenceCommandSubscription?.cancel();
    this._updateFileListSubscripton?.cancel();
    this._updateRecursiveSubscription?.cancel();
  }

  void updateFilesAndFolders() {
    //cancel old subscription
    this._foregroundMessageCommandSubscription?.cancel();
    this._updateFileListSubscripton?.cancel();

    this.loadingChangedCommand(true);

    _foregroundMessageCommandSubscription = _worker.isolateResponseCommand
        .where((event) => event is FileListMessage)
        .map((event) => event as FileListMessage)
        .where((event) =>
            (event.uri == uri && event.recursive == this.recursive.value) ||
            (this.recursive.value &&
                event.uri.toString().startsWith(uri.toString())))
        .listen((event) {
      if (event is FileListResponse) {
        bool changed = false;

        if (_addNewFiles(event.files, event.key)) {
          changed = true;
        }

        if (changed) {
          this.filesChangedCommand(files);
        }
      }
      if (event is FileListDone) {
        _logger.w("$managerKey (done - manager key)");
        _logger.w("${event.key} (done - event key)");
        this.loadingChangedCommand(false);
      }
    });

    this._updateFileListSubscripton = _worker.isolateResponseCommand
        .where((event) => event is FileUpdateMsg)
        .map((event) => event as FileUpdateMsg)
        .listen((event) {
      _logger.w("$managerKey (delete)");
      if (files.contains(event.file)) {
        if (event.file.isDirectory) {
          files.removeWhere(
              (file) => file.uri.path.startsWith(event.file.uri.path));
        }

        files.remove(event.file);
        this.filesChangedCommand(files);
      }
    });

    _logger.w("$managerKey (start)");

    //todo: we are here directly using the worker, we should be going over the file manager bridge
    this._worker.sendRequest(FileListRequest(
          managerKey,
          uri,
          recursive.value,
        ));
  }

  /// Returns true if any files where added
  bool _addNewFiles(List<NcFile> filesFromEvent, String eventKey) {
    int size = files.length;
    filesFromEvent.where((file) => !files.contains(file)).forEach((file) {
      // add file to list
      files.add(file);
      // check if it is necessary to update list with recursice childs of file
      if (this.recursive.value &&
          file.isDirectory &&
          !_fileIsFromThisManager(eventKey)) {
        this._worker.sendRequest(FileListRequest(
              "$managerKey",
              file.uri,
              recursive.value,
            ));
      }
    });
    return size != files.length;
  }

  bool _fileIsFromThisManager(String eventKey) {
    return eventKey.startsWith(this.managerKey);
  }

  void refetch({Uri uri}) {
    this._uri = uri ?? this.uri;
    this.files = [];
    this.updateFilesAndFolders();
  }

  void initState() {
    this.updateFilesAndFolders();

    this._updatedMappingPreferenceCommandSubscription = getIt
        .get<MappingManager>()
        .mappingUpdatedCommand
        .listen((value) => this.refetch());

    this._updateRecursiveSubscription = getIt
        .get<SettingsManager>()
        .updateSettingCommand
        .where((event) => event.key == this.recursive.key)
        .map((event) => event as BoolPreference)
        .where((event) => event.value != this.recursive.value)
        .listen((event) {
      this.recursive = event;
      this.refetch();
    });

    this.selectFileCommand.listen((file) {
      bool selectionMode = this.isInSelectionMode;
      file.selected = !file.selected;
      file.selected ? selected.add(file) : selected.remove(file);
      //using updateImageCommand is more effective then filesChangedCommand since it is not updating the whole list
      //however, keep in mind that this will update all widgets displaying this file not only the one in the current view
      //it might be a good idea to create a view local version of this command that relays global updates
      getIt.get<FileManager>().updateImageCommand(file);
      if (selectionMode != this.isInSelectionMode) {
        this.selectionModeChanged(this.isInSelectionMode);
      }
    });
  }

  void deselectAll() async {
    final fileManager = getIt.get<FileManager>();
    this.selected.forEach((file) {
      file.selected = false;
      fileManager.updateImageCommand(file);
    });
    this.selected = List();
    this.selectionModeChanged(this.isInSelectionMode);
  }

  void selectAll() async {
    this
        .files
        .where((element) => !element.isDirectory)
        .forEach((element) => element.selected = true);
    this.selected = List();
    this
        .selected
        .addAll(this.files.where((element) => element.selected).toList());
    this.filesChangedCommand(this.files);
  }

  Future<bool> deleteSelected(local) async =>
      (local ? deleteSelectedLocal() : deleteSelectedRemote())
          .whenComplete(() => this.deselectAll());

  Future<bool> deleteSelectedLocal() async {
    this.selected.forEach(
      (file) {
        getIt.get<LocalFileService>().deleteFile(file.localFile);
        getIt.get<FileManager>().updateImageCommand(file);
      },
    );

    return true;
  }

  Future<bool> deleteSelectedRemote() async {
    Completer<bool> jobDone = Completer();

    this
        ._worker
        .sendRequest(DeleteFilesRequest(this.managerKey, this.selected));

    StreamSubscription deleteSub = this
        ._worker
        .isolateResponseCommand
        .where((event) => event.key == this.managerKey)
        .where((event) => event is DeleteFilesDone)
        .map((event) => event as DeleteFilesDone)
        .listen((event) {
      jobDone.complete(true);
    });

    return jobDone.future.whenComplete(() => deleteSub.cancel());
  }
}
