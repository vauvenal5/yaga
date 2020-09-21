import 'dart:async';

import 'package:flutter/material.dart';
import 'package:yaga/managers/file_manager.dart';
import 'package:yaga/managers/mapping_manager.dart';
import 'package:yaga/model/nc_file.dart';
import 'package:yaga/model/preference.dart';
import 'package:yaga/utils/service_locator.dart';

//todo-sv: refactor this class? see also category_tab.dart
//--> this is a very messed up mix of different concerns
class CategoryImageStateWrapper {
  List<DateTime> dates = [];
  Map<String, List<NcFile>> sortedFiles = Map();
  bool loading;

  StreamSubscription<NcFile> _updateFilesListCommandSubscription;
  StreamSubscription<MappingPreference> _updatedMappingPreferenceCommandSubscription;
  StreamSubscription<NcFile> _updateFileListSubscripton;
  
  //todo: refactor to pass only setState function
  State wrappedState;
  Uri uri;

  CategoryImageStateWrapper(this.wrappedState, this.uri);

  void dispose() {
    this._updateFilesListCommandSubscription.cancel();
    this._updatedMappingPreferenceCommandSubscription.cancel();
    this._updateFileListSubscripton.cancel();
  }

  void updateFilesAndFolders() {
    this.dates = [];
    this.sortedFiles = Map();
    
    wrappedState.setState(() {
      loading = true;
    });

    //cancel old subscription
    this._updateFilesListCommandSubscription?.cancel();
    
    this._updateFilesListCommandSubscription = getIt.get<FileManager>().listFiles(uri)
    .where((event) => !event.isDirectory)
    .listen(
      (file) {
        DateTime lastModified = file.lastModified;
        DateTime date = DateTime(lastModified.year, lastModified.month, lastModified.day);
        
        wrappedState.setState(() {
          if(!this.dates.contains(date)) {
            this.dates.add(date);
            this.dates.sort((date1, date2) => date2.compareTo(date1));
          }

          String key = createKey(date);
          sortedFiles.putIfAbsent(key, () => []);
          //todo-sv: this has to be solved in a better way... double calling happens for example when in path selector screen navigating to same path
          //todo-sv: dart magic matches the files properly however it will be better to add a custom equals --> how does dart runtime hashcode work? Oo
          if(!sortedFiles[key].contains(file)) {
            sortedFiles[key].add(file);
            sortedFiles[key].sort((a,b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
          }
        });
      },
      onDone: () => wrappedState.setState((){
        loading=false;
      })
    );
  }

  void initState() {
    this.updateFilesAndFolders();
    this._updatedMappingPreferenceCommandSubscription = getIt.get<MappingManager>().mappingUpdatedCommand
      .listen((value) => this.updateFilesAndFolders());
    this._updateFileListSubscripton = getIt.get<FileManager>().updateFileList.listen((file) {
      DateTime lastModified = file.lastModified;
      DateTime date = DateTime(lastModified.year, lastModified.month, lastModified.day);
      String key = createKey(date);
      wrappedState.setState(() {
        this.sortedFiles[key].remove(file);
        if(this.sortedFiles[key].isEmpty) {
          this.dates.remove(date);
          this.sortedFiles.remove(key);
        }
      });
    });
  }

  static String createKey(DateTime date) => date.toString().split(" ")[0];
}