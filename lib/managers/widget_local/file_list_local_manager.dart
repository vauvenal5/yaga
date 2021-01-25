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
import 'package:yaga/services/isolateable/nextcloud_service.dart';
import 'package:yaga/utils/forground_worker/foreground_worker.dart';
import 'package:yaga/utils/forground_worker/messages/files_action/copy_files_request.dart';
import 'package:yaga/utils/forground_worker/messages/files_action/files_action_done.dart';
import 'package:yaga/utils/forground_worker/messages/files_action/delete_files_request.dart';
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
  RxCommand<List<NcFile>, List<NcFile>> selectionChangedCommand =
      RxCommand.createSync((param) => param);

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

    //todo: in future communication with the background worker should be done by bridges & handlers, and not directly
    _foregroundMessageCommandSubscription = _worker.isolateResponseCommand
        .where((event) => event is FileListMessage)
        .map((event) => event as FileListMessage)
        .where((event) =>
            //file list may contain recursively loaded files; this is done so we minimize the UI thread merging of lists
            //todo: maybe there is a better approach to this
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
        .listen((event) => this._removeFileFromList(event.file));

    _logger.w("$managerKey (start)");

    //todo: we are here directly using the worker, we should be going over the file manager bridge
    this._worker.sendRequest(FileListRequest(
          managerKey,
          uri,
          recursive.value,
        ));
  }

  void _removeFileFromList(NcFile file) {
    _logger.w("$managerKey (delete)");
    if (files.contains(file)) {
      if (file.isDirectory) {
        files.removeWhere((file) => file.uri.path.startsWith(file.uri.path));
      }

      files.remove(file);
      this.filesChangedCommand(files);
    }
  }

  /// Returns true if any files where added
  bool _addNewFiles(List<NcFile> filesFromEvent, String eventKey) {
    int size = files.length;
    filesFromEvent.where((file) => !files.contains(file)).forEach((file) {
      // add file to list
      files.add(file);
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
      } else {
        this.selectionChangedCommand(this.selected);
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
    final fileManager = getIt.get<FileManager>();
    this.selected = List();
    this.files.where((element) => !element.isDirectory).forEach((file) {
      file.selected = true;
      this.selected.add(file);
      fileManager.updateImageCommand(file);
    });
    this.selectionChangedCommand(this.files);
  }

  Future<bool> deleteSelected(bool local) =>
      this._executeActionForSelection(DeleteFilesRequest(
        this.managerKey,
        this.selected,
        local,
      ));

  Future<bool> copySelected(Uri destination) =>
      this._executeActionForSelection(DestinationActionFilesRequest(
        this.managerKey,
        this.selected,
        destination,
      ));

  Future<bool> moveSelected(Uri destination) =>
      this._executeActionForSelection(DestinationActionFilesRequest(
        this.managerKey,
        this.selected,
        destination,
        action: DestinationAction.move,
      ));

  Future<bool> _executeActionForSelection(Message action) async {
    Completer<bool> jobDone = Completer();

    this._worker.sendRequest(action);

    StreamSubscription actionSub = this
        ._worker
        .isolateResponseCommand
        .where((event) => event.key == this.managerKey)
        .where((event) => event is FilesActionDone)
        .map((event) => event as FilesActionDone)
        .listen((event) {
      jobDone.complete(true);
    });

    return jobDone.future
        .whenComplete(() => actionSub.cancel())
        .whenComplete(() => this.deselectAll());
  }

  void cancelSelectionAction() {
    this._worker.sendRequest(FilesActionDone(this.managerKey));
  }

  bool get isRemoteUri =>
      getIt.get<NextCloudService>().isUriOfService(this.uri);
}
