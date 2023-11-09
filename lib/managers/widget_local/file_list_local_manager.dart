import 'dart:async';

import 'package:rx_command/rx_command.dart';
import 'package:uuid/uuid.dart';
import 'package:yaga/managers/file_manager/file_manager.dart';
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
import 'package:yaga/utils/forground_worker/messages/file_list_done.dart';
import 'package:yaga/utils/forground_worker/messages/file_list_request.dart';
import 'package:yaga/utils/forground_worker/messages/file_list_response.dart';
import 'package:yaga/utils/forground_worker/messages/file_update_msg.dart';
import 'package:yaga/utils/forground_worker/messages/files_action/delete_files_request.dart';
import 'package:yaga/utils/forground_worker/messages/files_action/destination_action_files_request.dart';
import 'package:yaga/utils/forground_worker/messages/files_action/files_action_done.dart';
import 'package:yaga/utils/forground_worker/messages/files_action/files_action_request.dart';
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
  List<NcFile> selected = [];
  final bool allowSelecting;
  SortConfig _sortConfig;

  RxCommand<bool, bool> loadingChangedCommand =
      RxCommand.createSync((param) => param, initialLastResult: false);
  late RxCommand<SortedFileList, SortedFileList> filesChangedCommand;
  late RxCommand<NcFile, NcFile> selectFileCommand =
      RxCommand.createSync((param) => param);
  late RxCommand<bool, bool> selectionModeChanged =
      RxCommand.createSync((param) => param, initialLastResult: false);
  late RxCommand<List<NcFile>, List<NcFile>> selectionChangedCommand =
      RxCommand.createSync((param) => param);

  StreamSubscription<MappingPreference>?
      _updatedMappingPreferenceCommandSubscription;
  StreamSubscription<FileUpdateMsg>? _updateFileListSubscripton;
  StreamSubscription<BoolPreference>? _updateRecursiveSubscription;

  //todo: we are here directly using the worker, we should be going over the file manager bridge
  final ForegroundWorker _worker;
  final FileManager _fileManager;
  StreamSubscription<Message>? _foregroundMessageCommandSubscription;
  StreamSubscription<Message>? _foregroundMergeSortSubscription;

  Uri _uri;
  late String managerKey;
  final bool favorites;

  bool get isInSelectionMode => selected.isNotEmpty;

  FileListLocalManager(
    this._uri,
    this.recursive,
    this._sortConfig, {
    this.allowSelecting = true,
    this.favorites = false,
  }) : _worker = getIt.get<ForegroundWorker>(), _fileManager = getIt.get<FileManager>() {
    filesChangedCommand = RxCommand.createSync(
      (param) => param,
      initialLastResult: emptyFileList,
    );
    Uuid uuid = const Uuid();
    managerKey = uuid.v1();
  }

  SortedFileList get sorted => filesChangedCommand.lastResult!;
  Uri get uri => _uri;
  SortConfig get sortConfig => _sortConfig;
  SortedFileList get emptyFileList {
    if (_sortConfig.sortType == SortType.list) {
      return SortedFileFolderList.empty(_sortConfig);
    } else {
      return SortedCategoryList.empty(_sortConfig);
    }
  }

  void dispose() {
    _foregroundMessageCommandSubscription?.cancel();
    _updatedMappingPreferenceCommandSubscription?.cancel();
    _updateFileListSubscripton?.cancel();
    _updateRecursiveSubscription?.cancel();
    _foregroundMergeSortSubscription?.cancel();
  }

  void updateFilesAndFolders() {
    //cancel old subscription
    _foregroundMessageCommandSubscription?.cancel();
    _updateFileListSubscripton?.cancel();

    loadingChangedCommand(true);

    //todo: why are we still rebuilding this subScriptions on refetch?
    //todo: in future communication with the background worker should be done by bridges & handlers, and not directly
    _foregroundMessageCommandSubscription = _fileManager.updateFilesCommand
        .where((event) =>
            //file list may contain recursively loaded files; this is done so we minimize the UI thread merging of lists
            //todo: maybe there is a better approach to this
            (event.uri == uri) ||
            (recursive.value &&
                event.uri.toString().startsWith(uri.toString())))
        .listen((event) {
      if (event is FileListResponse) {
        _logger.warning(
          "${event.key} (received list - #images: ${event.files.files.length})",
        );
        // if uri is not equal then it could be a sub dir loaded by the copy command for example
        if (event.key == managerKey && event.uri == uri) {
          _showNewFiles(event.files);
        } else {
          // in this case we are interested in the data but can not tell if the data is not missing crutial parts
          // todo: can we build a bridge for this?
          _sendMergeSortRequest(
            MergeSortRequest(
              managerKey,
              //primarely to counter hot reloads
              filesChangedCommand.lastResult ?? emptyFileList,
              event.files,
              uri: uri,
              recursive: recursive.value,
            ),
          );
        }
      }

      if (event is FileListDone && event.key == managerKey) {
        _logger.warning("$managerKey (done - manager key)");
        _logger.warning("${event.key} (done - event key)");
        loadingChangedCommand(false);
      }
    });

    _updateFileListSubscripton = _fileManager.fileUpdateMessage
        .listen((event) => _removeFileFromList(event.file));

    _logger.warning("$managerKey (start)");

    _fileManager.fetchFileListCommand(FileListRequest(
      managerKey,
      uri,
      _sortConfig,
      recursive: recursive.value,
      favorites: favorites,
    ));
  }

  void _showNewFiles(SortedFileList files) {
    if (files.config == _sortConfig) {
      filesChangedCommand(files);
    } else {
      _sendMergeSortRequest(
        MergeSortRequest(
          managerKey,
          emptyFileList,
          files,
        ),
      );
    }
  }

  void _sendMergeSortRequest(MergeSortRequest request) =>
      _worker.sendRequest(request);

  //todo: changing the view type while fetching the list will not fetch all files
  bool setSortConfig(SortConfig sortConfig) {
    final changed = sortConfig != _sortConfig;

    _sortConfig = sortConfig;

    if (loadingChangedCommand.lastResult!) {
      return changed;
    }

    if (changed) {
      //todo: loading changed has to be improved... currently if we are fetching a list and changing the config simulatniously the first to be done will stop the loading indicator
      loadingChangedCommand(true);
      _sendMergeSortRequest(
        MergeSortRequest(
          managerKey,
          emptyFileList,
          filesChangedCommand.lastResult!,
          updateLoading: true,
        ),
      );
    }
    return changed;
  }

  void _removeFileFromList(NcFile file) {
    _logger.warning("$managerKey (delete)");
    final SortedFileList files = filesChangedCommand.lastResult!;
    //todo: delete and re-sort are interfearing with each other
    if (files.remove(file)) {
      //todo: what happens is that the deletes might be triggered on states before the resort is done
      filesChangedCommand(files);
    }
  }

  /* bool _fileIsFromThisManager(String eventKey) {
    return eventKey.startsWith(managerKey);
  } */

  void refetch({Uri? uri}) {
    _uri = uri ?? _uri;
    updateFilesAndFolders();
  }

  void initState() {
    updateFilesAndFolders();

    _updatedMappingPreferenceCommandSubscription =
        getIt.get<MappingManager>().mappingUpdatedCommand.listen(
      (value) {
        // currently local file is not checked when comparing two NcFiles
        // thats why we have to clear the entire list and repopulate it
        // otherwise availability icons will not be refreshed
        // because NcFiles in list will not be refreshed and will still point to old local files
        removeAll();
        refetch();
      },
    );

    _updateRecursiveSubscription = getIt
        .get<SettingsManager>()
        .updateSettingCommand
        .where((event) => event.key == recursive.key)
        .map((event) => event as BoolPreference)
        .where((event) => event.value != recursive.value)
        .listen((event) {
      recursive = event;
      refetch();
    });

    selectFileCommand.where((_) => allowSelecting).listen((file) {
      final bool selectionMode = isInSelectionMode;
      file.selected = !file.selected;
      file.selected ? selected.add(file) : selected.remove(file);
      //using updateImageCommand is more effective then filesChangedCommand since it is not updating the whole list
      //however, keep in mind that this will update all widgets displaying this file not only the one in the current view
      //it might be a good idea to create a view local version of this command that relays global updates
      getIt.get<FileManager>().updateImageCommand(file);
      if (selectionMode != isInSelectionMode) {
        selectionModeChanged(isInSelectionMode);
      } else {
        selectionChangedCommand(selected);
      }
    });

    _foregroundMergeSortSubscription = _worker.isolateResponseCommand
        .where((event) => event.key == managerKey)
        .where((event) => event is MergeSortDone)
        .map((event) => event as MergeSortDone)
        .listen((event) {
      _showNewFiles(event.sorted);
      if (event.updateLoading) {
        loadingChangedCommand(false);
      }
    });
  }

  Future<void> removeAll() async {
    filesChangedCommand(filesChangedCommand.lastResult!..removeAll());
  }

  Future<void> deselectAll() async {
    final fileManager = getIt.get<FileManager>();
    for (final file in selected) {
      file.selected = false;
      fileManager.updateImageCommand(file);
    }
    selected = [];
    selectionModeChanged(isInSelectionMode);
  }

  Future<void> selectAll() async {
    final fileManager = getIt.get<FileManager>();
    selected = [];
    final sorted = filesChangedCommand.lastResult;
    for (final file in sorted!.files) {
      file.selected = true;
      selected.add(file);
      fileManager.updateImageCommand(file);
    }
    selectionChangedCommand(selected);
  }

  Future<bool> deleteSelected({required bool local}) =>
      _executeActionForSelection(DeleteFilesRequest(
        key: managerKey,
        files: selected,
        local: local,
        sourceDir: uri,
      ));

  Future<bool> copySelected(Uri destination, {bool overwrite = false}) =>
      _executeActionForSelection(DestinationActionFilesRequest(
        key: managerKey,
        files: selected,
        destination: destination,
        overwrite: overwrite,
        sourceDir: uri,
      ));

  Future<bool> moveSelected(Uri destination, {bool overwrite = false}) =>
      _executeActionForSelection(DestinationActionFilesRequest(
        key: managerKey,
        files: selected,
        destination: destination,
        action: DestinationAction.move,
        overwrite: overwrite,
        sourceDir: uri,
      ));

  Future<bool> _executeActionForSelection(FilesActionRequest action) async {
    final Completer<bool> jobDone = Completer();

    _fileManager.filesActionCommand(action);

    final StreamSubscription actionSub = _fileManager.filesActionDoneCommand
        .where((event) => event.key == managerKey)
        .listen((event) {
      jobDone.complete(true);

      _fileManager.fetchFileListCommand(FileListRequest(
        managerKey,
        event.destination,
        _sortConfig,
      ));
    });

    return jobDone.future
        .whenComplete(() => actionSub.cancel())
        .whenComplete(() => deselectAll());
  }

  void cancelSelectionAction() {
    _worker.sendRequest(FilesActionDone(managerKey, _uri));
  }

  bool get isRemoteUri => getIt.get<NextCloudService>().isUriOfService(uri);
}
