import 'dart:async';

import 'package:rx_command/rx_command.dart';
import 'package:uuid/uuid.dart';
import 'package:yaga/managers/file_manager.dart';
import 'package:yaga/managers/isolateable/mapping_manager.dart';
import 'package:yaga/managers/settings_manager.dart';
import 'package:yaga/model/nc_file.dart';
import 'package:yaga/model/preferences/bool_preference.dart';
import 'package:yaga/model/preferences/mapping_preference.dart';
import 'package:yaga/model/sort_config.dart';
import 'package:yaga/model/sorted_category_list.dart';
import 'package:yaga/model/sorted_file_folder_list.dart';
import 'package:yaga/model/sorted_file_list.dart';
import 'package:yaga/services/isolateable/nextcloud_service.dart';
import 'package:yaga/utils/forground_worker/foreground_worker.dart';
import 'package:yaga/utils/forground_worker/messages/files_action/destination_action_files_request.dart';
import 'package:yaga/utils/forground_worker/messages/files_action/files_action_done.dart';
import 'package:yaga/utils/forground_worker/messages/files_action/delete_files_request.dart';
import 'package:yaga/utils/forground_worker/messages/file_list_done.dart';
import 'package:yaga/utils/forground_worker/messages/file_list_message.dart';
import 'package:yaga/utils/forground_worker/messages/file_list_request.dart';
import 'package:yaga/utils/forground_worker/messages/file_list_response.dart';
import 'package:yaga/utils/forground_worker/messages/file_update_msg.dart';
import 'package:yaga/utils/forground_worker/messages/merge_sort_done.dart';
import 'package:yaga/utils/forground_worker/messages/merge_sort_request.dart';
import 'package:yaga/utils/forground_worker/messages/message.dart';
import 'package:yaga/utils/logger.dart';
import 'package:yaga/utils/service_locator.dart';

// this is a widget local manager, meaning that it is intendet to exist per widget that needs its functionality
// however this also means that the owning widget has to manage init and disposal
// treat it like local state
class FileListLocalManager {
  final _logger = YagaLogger.getLogger(FileListLocalManager);

  BoolPreference recursive;
  List<NcFile> selected = List();
  final bool allowSelecting;
  SortConfig _sortConfig;

  RxCommand<bool, bool> loadingChangedCommand;
  RxCommand<SortedFileList, SortedFileList> filesChangedCommand;
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
  StreamSubscription<Message> _foregroundMergeSortSubscription;

  Uuid uuid = Uuid();

  Uri _uri;
  String managerKey;

  bool get isInSelectionMode => this.selected.length > 0;

  FileListLocalManager(
    this._uri,
    this.recursive,
    this._sortConfig, {
    this.allowSelecting = true,
  }) {
    _worker = getIt.get<ForegroundWorker>();
    loadingChangedCommand =
        RxCommand.createSync((param) => param, initialLastResult: false);
    filesChangedCommand = RxCommand.createSync(
      (param) => param,
      initialLastResult: this.emptyFileList,
    );
    managerKey = uuid.v1();
  }

  SortedFileList get sorted => this.filesChangedCommand.lastResult;
  Uri get uri => this._uri;
  SortConfig get sortConfig => _sortConfig;
  SortedFileList get emptyFileList => _sortConfig.sortType == SortType.list
      ? SortedFileFolderList.empty(_sortConfig)
      : SortedCategoryList.empty(_sortConfig);

  void dispose() {
    this._foregroundMessageCommandSubscription?.cancel();
    this._updatedMappingPreferenceCommandSubscription?.cancel();
    this._updateFileListSubscripton?.cancel();
    this._updateRecursiveSubscription?.cancel();
    this._foregroundMergeSortSubscription?.cancel();
  }

  void updateFilesAndFolders() {
    //cancel old subscription
    this._foregroundMessageCommandSubscription?.cancel();
    this._updateFileListSubscripton?.cancel();

    this.loadingChangedCommand(true);

    //todo: why are we still rebuilding this subScriptions on refetch?
    //todo: in future communication with the background worker should be done by bridges & handlers, and not directly
    _foregroundMessageCommandSubscription = _worker.isolateResponseCommand
        .where((event) => event is FileListMessage)
        .map((event) => event as FileListMessage)
        .where((event) =>
            //file list may contain recursively loaded files; this is done so we minimize the UI thread merging of lists
            //todo: maybe there is a better approach to this
            (event.uri == uri) ||
            (this.recursive.value &&
                event.uri.toString().startsWith(uri.toString())))
        .listen((event) {
      if (event is FileListResponse) {
        _logger.warning(
          "${event.key} (received list - #images: ${event.files.files.length})",
        );
        // if uri is not equal then it could be a sub dir loaded by the copy command for example
        if (event.key == this.managerKey && event.uri == uri) {
          _showNewFiles(event.files);
        } else {
          // in this case we are interested in the data but can not tell if the data is not missing crutial parts
          // todo: can we build a bridge for this?
          this._sendMergeSortRequest(
            MergeSortRequest(
              this.managerKey,
              //primarely to counter hot reloads
              this.filesChangedCommand.lastResult ?? this.emptyFileList,
              event.files,
              uri: this.uri,
              recursive: this.recursive.value,
            ),
          );
        }
      }

      if (event is FileListDone && event.key == this.managerKey) {
        _logger.warning("$managerKey (done - manager key)");
        _logger.warning("${event.key} (done - event key)");
        this.loadingChangedCommand(false);
      }
    });

    this._updateFileListSubscripton = _worker.isolateResponseCommand
        .where((event) => event is FileUpdateMsg)
        .map((event) => event as FileUpdateMsg)
        .listen((event) => this._removeFileFromList(event.file));

    _logger.warning("$managerKey (start)");

    //todo: we are here directly using the worker, we should be going over the file manager bridge
    this._worker.sendRequest(FileListRequest(
          managerKey,
          uri,
          recursive.value,
          this._sortConfig,
        ));
  }

  void _showNewFiles(SortedFileList files) {
    if (files.config == this._sortConfig) {
      this.filesChangedCommand(files);
    } else {
      this._sendMergeSortRequest(
        MergeSortRequest(
          this.managerKey,
          this.emptyFileList,
          files,
        ),
      );
    }
  }

  void _sendMergeSortRequest(MergeSortRequest request) =>
      this._worker.sendRequest(request);

  //todo: changing the view type while fetching the list will not fetch all files
  bool setSortConfig(SortConfig sortConfig) {
    final changed = sortConfig != _sortConfig;

    this._sortConfig = sortConfig;

    if (this.loadingChangedCommand.lastResult) {
      return changed;
    }

    if (changed) {
      //todo: loading changed has to be improved... currently if we are fetching a list and changing the config simulatniously the first to be done will stop the loading indicator
      this.loadingChangedCommand(true);
      this._sendMergeSortRequest(
        MergeSortRequest(
          this.managerKey,
          this.emptyFileList,
          this.filesChangedCommand.lastResult,
          updateLoading: true,
        ),
      );
    }
    return changed;
  }

  void _removeFileFromList(NcFile file) {
    _logger.warning("$managerKey (delete)");
    SortedFileList files = this.filesChangedCommand.lastResult;
    //todo: delete and re-sort are interfearing with each other
    if (files.remove(file)) {
      //todo: what happens is that the deletes might be triggered on states before the resort is done
      this.filesChangedCommand(files);
    }
  }

  bool _fileIsFromThisManager(String eventKey) {
    return eventKey.startsWith(this.managerKey);
  }

  void refetch({Uri uri}) {
    this._uri = uri ?? this.uri;
    this.updateFilesAndFolders();
  }

  void initState() {
    this.updateFilesAndFolders();

    this._updatedMappingPreferenceCommandSubscription =
        getIt.get<MappingManager>().mappingUpdatedCommand.listen(
      (value) {
        // currently local file is not checked when comparing two NcFiles
        // thats why we have to clear the entire list and repopulate it
        // otherwise availability icons will not be refreshed
        // because NcFiles in list will not be refreshed and will still point to old local files
        this.removeAll();
        this.refetch();
      },
    );

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

    this.selectFileCommand.where((_) => allowSelecting).listen((file) {
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

    this._foregroundMergeSortSubscription = _worker.isolateResponseCommand
        .where((event) => event.key == this.managerKey)
        .where((event) => event is MergeSortDone)
        .map((event) => event as MergeSortDone)
        .listen((event) {
      this._showNewFiles(event.sorted);
      if (event.updateLoading) {
        this.loadingChangedCommand(false);
      }
    });
  }

  void removeAll() async {
    this.filesChangedCommand(this.filesChangedCommand.lastResult..removeAll());
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
    final sorted = this.filesChangedCommand.lastResult;
    sorted.files.forEach((file) {
      file.selected = true;
      this.selected.add(file);
      fileManager.updateImageCommand(file);
    });
    this.selectionChangedCommand(this.selected);
  }

  Future<bool> deleteSelected(bool local) =>
      this._executeActionForSelection(DeleteFilesRequest(
        this.managerKey,
        this.selected,
        local,
      ));

  Future<bool> copySelected(Uri destination, {bool overwrite = false}) =>
      this._executeActionForSelection(DestinationActionFilesRequest(
        this.managerKey,
        this.selected,
        destination,
        this._sortConfig,
        overwrite: overwrite,
      ));

  Future<bool> moveSelected(Uri destination, {bool overwrite = false}) =>
      this._executeActionForSelection(DestinationActionFilesRequest(
        this.managerKey,
        this.selected,
        destination,
        this._sortConfig,
        action: DestinationAction.move,
        overwrite: overwrite,
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
