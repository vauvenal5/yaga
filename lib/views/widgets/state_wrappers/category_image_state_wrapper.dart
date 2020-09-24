import 'dart:async';

import 'package:rx_command/rx_command.dart';
import 'package:rxdart/rxdart.dart';
import 'package:flutter/material.dart';
import 'package:yaga/managers/file_manager.dart';
import 'package:yaga/managers/mapping_manager.dart';
import 'package:yaga/managers/settings_manager.dart';
import 'package:yaga/model/nc_file.dart';
import 'package:yaga/model/preference.dart';
import 'package:yaga/utils/service_locator.dart';

//todo-sv: refactor this class? see also category_tab.dart
//--> this is a very messed up mix of different concerns
//--> setState should be moved out of here
//--> maybe this itself should be a manager? However a non singleton manager, build by a factory? --> a widget specific manager?
//--> loading could be a stream of bool events
class CategoryImageStateWrapper {
  List<NcFile> files = List();
  BoolPreference recursive;

  RxCommand<bool, bool> loadingChangedCommand;

  StreamSubscription<NcFile> _updateFilesListCommandSubscription;
  StreamSubscription<MappingPreference> _updatedMappingPreferenceCommandSubscription;
  StreamSubscription<NcFile> _updateFileListSubscripton;
  StreamSubscription<BoolPreference> _updateRecursiveSubscription;
  
  //todo: refactor to pass only setState function
  State wrappedState;
  Uri uri;

  CategoryImageStateWrapper(this.wrappedState, this.uri, this.recursive) {
    loadingChangedCommand = RxCommand.createSync((param) => param);
  }

  void dispose() {
    this._updateFilesListCommandSubscription.cancel();
    this._updatedMappingPreferenceCommandSubscription.cancel();
    this._updateFileListSubscripton.cancel();
    this._updateRecursiveSubscription.cancel();
  }

  void updateFilesAndFolders() {
    this.files = [];
    
    this.loadingChangedCommand(true);

    //cancel old subscription
    this._updateFilesListCommandSubscription?.cancel();
    
    this._updateFilesListCommandSubscription = getIt.get<FileManager>().listFiles(uri)
    .flatMap((event) => event.isDirectory && this.recursive.value ? getIt.get<FileManager>().listFiles(event.uri) : Stream.value(event))
    .listen(
      (file) {
        wrappedState.setState(() {
          //todo-sv: dart magic matches the files properly however it will be better to add a custom equals --> how does dart runtime hashcode work? Oo
          if(!files.contains(file)) {
            files.add(file);
          }
        });
      },
      onDone: () => this.loadingChangedCommand(false)
    );
  }

  void initState() {
    this.updateFilesAndFolders();
    
    this._updatedMappingPreferenceCommandSubscription = getIt.get<MappingManager>().mappingUpdatedCommand
      .listen((value) => this.updateFilesAndFolders());
    
    //todo: here we do need a check if the file is part of this list also in regard of the upcoming persistend tab state feature
    this._updateFileListSubscripton = getIt.get<FileManager>().updateFileList.listen((file) {
      wrappedState.setState(() {
        this.files.remove(file);
      });
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