import 'dart:async';

import 'package:rx_command/rx_command.dart';
import 'package:rxdart/rxdart.dart';
import 'package:yaga/managers/file_manager.dart';
import 'package:yaga/managers/mapping_manager.dart';
import 'package:yaga/managers/settings_manager.dart';
import 'package:yaga/model/nc_file.dart';
import 'package:yaga/model/preference.dart';
import 'package:yaga/utils/service_locator.dart';

//todo-sv: refactor this class? see also category_tab.dart
//--> passing uri should be solved differently
//--> try performence behaviour when handling full lists from backend instead of single files
// this is a widget local manager, meaning that it is intendet to exist per widget that needs its functionality
class FileListLocalManager {
  List<NcFile> files = List();
  BoolPreference recursive;

  RxCommand<bool, bool> loadingChangedCommand;
  RxCommand<List<NcFile>, List<NcFile>> filesChangedCommand;

  StreamSubscription<List<NcFile>> _updateFilesListCommandSubscription;
  StreamSubscription<MappingPreference> _updatedMappingPreferenceCommandSubscription;
  StreamSubscription<NcFile> _updateFileListSubscripton;
  StreamSubscription<BoolPreference> _updateRecursiveSubscription;
  
  Uri uri;

  FileListLocalManager(this.uri, this.recursive) {
    loadingChangedCommand = RxCommand.createSync((param) => param, initialLastResult: true);
    filesChangedCommand = RxCommand.createSync((param) => param, initialLastResult: []);
  }

  void dispose() {
    this._updateFilesListCommandSubscription?.cancel();
    this._updatedMappingPreferenceCommandSubscription?.cancel();
    this._updateFileListSubscripton?.cancel();
    this._updateRecursiveSubscription?.cancel();
  }

  void updateFilesAndFolders() {
    this.files = [];
    
    this.loadingChangedCommand(true);

    //cancel old subscription
    this._updateFilesListCommandSubscription?.cancel();
    
    // this._updateFilesListCommandSubscription = getIt.get<FileManager>().listFiles(uri, recursive: this.recursive.value)
    // .listen(
    //   (file) {
    //     //todo-sv: dart magic matches the files properly however it will be better to add a custom equals --> how does dart runtime hashcode work? Oo
    //     if(!files.contains(file)) {
    //       files.add(file);
    //       this.filesChangedCommand(files);
    //     }
    //   },
    //   onDone: () => this.loadingChangedCommand(false)
    // );

    this._updateFilesListCommandSubscription = getIt.get<FileManager>().listFileLists(uri, recursive: this.recursive.value)
    .listen(
      (fileList) {
        bool changed = false;
        //todo-sv: dart magic matches the files properly however it will be better to add a custom equals --> how does dart runtime hashcode work? Oo
        fileList.forEach((file) { 
          if(!files.contains(file)) {
            files.add(file);
            changed = true;
          }
        });

        if(changed) {
          this.filesChangedCommand(files);
        }
      },
      onDone: () => this.loadingChangedCommand(false)
    );
  }

  void initState() {
    this.updateFilesAndFolders();
    
    this._updatedMappingPreferenceCommandSubscription = getIt.get<MappingManager>().mappingUpdatedCommand
      .listen((value) => this.updateFilesAndFolders());
    
    this._updateFileListSubscripton = getIt.get<FileManager>().updateFileList.listen((file) {
      if(files.contains(file)) {
        files.remove(file);
        this.filesChangedCommand(files);
      }
    });

    this._updateRecursiveSubscription = getIt.get<SettingsManager>().updateSettingCommand
      .where((event) => event.key == this.recursive.key)
      .map((event) => event as BoolPreference)
      .where((event) => event.value != this.recursive.value)
      .listen((event) {
        this.recursive = event;
        this.updateFilesAndFolders();
      });
  }
}