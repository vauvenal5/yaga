import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_sticky_header/flutter_sticky_header.dart';
import 'package:yaga/managers/file_manager.dart';
import 'package:yaga/model/nc_file.dart';
import 'package:yaga/utils/image_screen_arguments.dart';
import 'package:yaga/utils/service_locator.dart';
import 'package:yaga/services/local_image_provider_service.dart';
import 'package:rxdart/rxdart.dart';
import 'package:yaga/views/screens/image_screen.dart';
import 'package:yaga/views/widgets/remote_image_widget.dart';

class CategoryWidget extends StatefulWidget {
  final Uri _uri;
  final Function _onFolderTap;

  CategoryWidget(this._uri, this._onFolderTap);

  @override
  State<StatefulWidget> createState() => CategoryWidgetState();
}

class CategoryWidgetState extends State<CategoryWidget> {
  List<DateTime> _dates = [];
  Map<String, List<NcFile>> _sortedFiles = Map();
  StreamSubscription<NcFile> _updateFilesListCommandSubscription;

  CategoryWidgetState() {
    this._updateFilesListCommandSubscription = getIt.get<FileManager>().updateFilesListCommand
    .where((event) => event.uri.path.startsWith(widget._uri.path))
    .where((event) => !event.isDirectory)
    .listen((file) {
      DateTime lastModified = file.lastModified;
      DateTime date = DateTime(lastModified.year, lastModified.month, lastModified.day);
      
      setState((){
        if(!this._dates.contains(date)) {
          this._dates.add(date);
          this._dates.sort((date1, date2) => date2.compareTo(date1));
        }

        String key = this._createKey(date);
        _sortedFiles.putIfAbsent(key, () => []);
        //todo-sv: this has to be solved in a better way... double calling happens for example when in path selector screen navigating to same path
        if(!_sortedFiles[key].contains(file)) {
          _sortedFiles[key].add(file);
        }
      });
    });
  }

  @override
  void dispose() {
    this._updateFilesListCommandSubscription.cancel();
    super.dispose();
  }

  void _updateFilesAndFolders() {
    this._dates = [];
    this._sortedFiles = Map();
    getIt.get<FileManager>().listFilesCommand(widget._uri);
  }

  @override
  void initState() {
    super.initState();
    this._updateFilesAndFolders();
  }
  

  @override
  void didUpdateWidget(CategoryWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    this._updateFilesAndFolders();
  }

  String _createKey(DateTime date) => date.toString().split(" ")[0];

  @override
  Widget build(BuildContext context) {
    print("drawing list");

    List<Widget> slivers = [];

    _dates.forEach((element) {
      print("rebuilding list");
      String key = this._createKey(element);
      slivers.add(SliverStickyHeader(
        key: ValueKey(key),
        header: Container(
          height: 30.0,
          color: Theme.of(context).accentColor,
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          alignment: Alignment.centerLeft,
          child: Text(
            key,
            style: const TextStyle(color: Colors.white),
          ),
        ),
        sliver: SliverGrid(
          delegate: SliverChildBuilderDelegate(
            (BuildContext context, int index) {
              return InkWell(
                onTap: () => Navigator.pushNamed(context, ImageScreen.route, arguments: ImageScreenArguments(_sortedFiles[key], index, key)),
                child: RemoteImageWidget(_sortedFiles[key][index], key: ValueKey(_sortedFiles[key][index].uri.path), cacheWidth: 512, ),
              );
              //return Image.file(_sortedFiles[key][index].localFile, cacheWidth: 64, key: ValueKey(_sortedFiles[key][index].uri.path),);
            },
            childCount: _sortedFiles[key].length
          ), 
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 2,
            mainAxisSpacing: 2,
          )
        )
      ));
    });
    
    return CustomScrollView(

      slivers: slivers,
    );
  }
}