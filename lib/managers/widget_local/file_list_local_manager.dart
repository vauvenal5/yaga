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
import 'package:yaga/utils/forground_worker/foreground_worker.dart';
import 'package:yaga/utils/forground_worker/messages/file_list_done.dart';
import 'package:yaga/utils/forground_worker/messages/file_list_request.dart';
import 'package:yaga/utils/forground_worker/messages/file_list_response.dart';
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
  StreamSubscription<NcFile> _updateFileListSubscripton;
  StreamSubscription<BoolPreference> _updateRecursiveSubscription;

  ForegroundWorker _worker;
  StreamSubscription<Message> _foregroundMessageCommandSubscription;

  Uuid uuid = Uuid();

  Uri uri;

  FileListLocalManager(this.uri, this.recursive) {
    _worker = getIt.get<ForegroundWorker>();
    loadingChangedCommand =
        RxCommand.createSync((param) => param, initialLastResult: false);
    filesChangedCommand =
        RxCommand.createSync((param) => param, initialLastResult: []);
  }

  void dispose() {
    this._foregroundMessageCommandSubscription?.cancel();

    this._updatedMappingPreferenceCommandSubscription?.cancel();
    this._updateFileListSubscripton?.cancel();
    this._updateRecursiveSubscription?.cancel();
  }

  void updateFilesAndFolders() {
    //generating key per refresh to ensure that if the user refreshes twice the first will not cancel the 2nd
    String key = uuid.v1();

    this.loadingChangedCommand(true);

    //cancel old subscription
    this._foregroundMessageCommandSubscription?.cancel();

    _foregroundMessageCommandSubscription = _worker.isolateResponseCommand
        .where((event) => event.key == key)
        .listen((event) {
      if (event is FileListResponse) {
        bool changed = false;
        //todo-sv: dart magic matches the files properly however it will be better to add a custom equals --> how does dart runtime hashcode work? Oo
        event.files.forEach((file) {
          if (!files.contains(file)) {
            files.add(file);
            changed = true;
          }
        });

        if (changed) {
          // List<NcFile> clone = List.from(files);
          this.filesChangedCommand(files);
        }
      }
      if (event is FileListDone) {
        _foregroundMessageCommandSubscription.cancel();
        this.loadingChangedCommand(false);
      }
    });

    this._worker.sendRequest(FileListRequest(key, uri, recursive.value));
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

    //todo: strictly speaking this is wrong and has been wrong for ever -> remove is only valid if we are in the correct list!
    //for example when we are in the browse tab and a file has been moved from a inner folder to a outter folder the file will be removed from both views
    this._updateFileListSubscripton =
        getIt.get<FileManager>().updateFileList.listen((file) {
      if (files.contains(file)) {
        files.remove(file);
        this.filesChangedCommand(files);
      }
    });

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
