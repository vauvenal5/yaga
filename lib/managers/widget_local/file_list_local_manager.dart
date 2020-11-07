import 'dart:async';

import 'package:logger/logger.dart';
import 'package:rx_command/rx_command.dart';
import 'package:uuid/uuid.dart';
import 'package:yaga/managers/isolateable/mapping_manager.dart';
import 'package:yaga/managers/settings_manager.dart';
import 'package:yaga/model/nc_file.dart';
import 'package:yaga/model/preferences/bool_preference.dart';
import 'package:yaga/model/preferences/mapping_preference.dart';
import 'package:yaga/utils/forground_worker/foreground_worker.dart';
import 'package:yaga/utils/forground_worker/messages/file_list_done.dart';
import 'package:yaga/utils/forground_worker/messages/file_list_message.dart';
import 'package:yaga/utils/forground_worker/messages/file_list_request.dart';
import 'package:yaga/utils/forground_worker/messages/file_list_response.dart';
import 'package:yaga/utils/forground_worker/messages/file_update_msg.dart';
import 'package:yaga/utils/forground_worker/messages/message.dart';
import 'package:yaga/utils/logger.dart';
import 'package:yaga/utils/service_locator.dart';

//todo-sv: refactor this class? see also category_tab.dart
//--> passing uri should be solved differently
//--> try performence behaviour when handling full lists from backend instead of single files
// this is a widget local manager, meaning that it is intendet to exist per widget that needs its functionality
class FileListLocalManager {
  Logger _logger = getLogger(FileListLocalManager);
  List<NcFile> files = List();
  BoolPreference recursive;

  RxCommand<bool, bool> loadingChangedCommand;
  RxCommand<List<NcFile>, List<NcFile>> filesChangedCommand;

  StreamSubscription<MappingPreference>
      _updatedMappingPreferenceCommandSubscription;
  StreamSubscription<FileUpdateMsg> _updateFileListSubscripton;
  StreamSubscription<BoolPreference> _updateRecursiveSubscription;

  ForegroundWorker _worker;
  StreamSubscription<Message> _foregroundMessageCommandSubscription;

  Uuid uuid = Uuid();

  Uri uri;
  String managerKey;

  FileListLocalManager(this.uri, this.recursive) {
    _worker = getIt.get<ForegroundWorker>();
    loadingChangedCommand =
        RxCommand.createSync((param) => param, initialLastResult: false);
    filesChangedCommand =
        RxCommand.createSync((param) => param, initialLastResult: []);
    managerKey = uuid.v1();
  }

  void dispose() {
    this._foregroundMessageCommandSubscription?.cancel();

    this._updatedMappingPreferenceCommandSubscription?.cancel();
    this._updateFileListSubscripton?.cancel();
    this._updateRecursiveSubscription?.cancel();
  }

  void updateFilesAndFolders() {
    //generating key per refresh to ensure that if the user refreshes twice the first will not cancel the 2nd
    //todo: key maybe not necessary anymore
    String key = uuid.v1();
    // String key = uri.toString();

    //cancel old subscription
    this._foregroundMessageCommandSubscription?.cancel();
    this._updateFileListSubscripton?.cancel();

    this.loadingChangedCommand(true);

    //todo: here we have still an update issue...
    //...the home view might be interested in the updates coming from the browseview
    //...I am not sure how we can make this work together with the keys
    //...the key thingy is only a visual issue for the done event!
    _foregroundMessageCommandSubscription = _worker.isolateResponseCommand
        // .where((event) => event.key == key)
        .where((event) => event is FileListMessage)
        .map((event) => event as FileListMessage)
        .where((event) =>
            event.uri == uri ||
            (recursive.value &&
                event.uri.toString().startsWith(uri.toString())))
        .listen((event) {
      if (event is FileListResponse) {
        bool changed = false;

        _logger.w("$managerKey (add - manager)");
        _logger.w("$key (add - key)");
        _logger.w("${event.key} (add - event key)");

        if (_addNewFiles(event.files, event.key)) {
          changed = true;
        }

        if (changed) {
          // List<NcFile> clone = List.from(files);
          this.filesChangedCommand(files);
        }
      }
      if (event is FileListDone) {
        //todo: i am not sure if we still need this however in any case something is wrong
        // if (!event.key.endsWith(key)) {
        //   return;
        // }
        // _foregroundMessageCommandSubscription.cancel();
        this.loadingChangedCommand(false);
      }
    });

    //todo: strictly speaking this is wrong and has been wrong for ever -> remove is only valid if we are in the correct list!
    //for example when we are in the browse tab and a file has been moved from a inner folder to a outter folder the file will be removed from both views
    //
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

    //todo: key should probably be a complex object
    this._worker.sendRequest(FileListRequest(
          "$managerKey:$key",
          uri,
          recursive.value,
        ));
  }

  /// Returns true if any files where added
  bool _addNewFiles(List<NcFile> filesFromEvent, String eventKey) {
    return _executeSizeChangingFunction(
      filesFromEvent,
      (files, filesFromEvent) =>
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
      }),
    );
  }

  bool _fileIsFromThisManager(String eventKey) {
    return eventKey.startsWith(this.managerKey);
  }

  /// Returns true if any files where removed
  bool _removeDeletedFiles(List<NcFile> filesFromEvent) {
    return _executeSizeChangingFunction(
      filesFromEvent,
      (files, filesFromEvent) =>
          files.removeWhere((file) => !filesFromEvent.contains(file)),
    );
  }

  bool _executeSizeChangingFunction(List<NcFile> filesFromEvent,
      Function(List<NcFile> files, List<NcFile> filesFromEvent) manipulate) {
    int size = files.length;
    manipulate(files, filesFromEvent);
    return size != files.length;
  }

  void refetch() {
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
  }
}
