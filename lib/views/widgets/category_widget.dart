import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_sticky_header/flutter_sticky_header.dart';
import 'package:yaga/model/nc_file.dart';
import 'package:yaga/utils/service_locator.dart';
import 'package:yaga/services/local_image_provider_service.dart';
import 'package:rxdart/rxdart.dart';

class CategoryWidget extends StatefulWidget {
  final String _path;
  final Function _onFolderTap;

  CategoryWidget(this._path, this._onFolderTap);

  @override
  State<StatefulWidget> createState() => CategoryWidgetState();
}

class CategoryWidgetState extends State<CategoryWidget> {
  List<DateTime> _dates = [];
  Map<String, List<NcFile>> _sortedFiles = Map();

  void _updateFilesAndFolders() {
    this._dates = [];
    this._sortedFiles = Map();

    getIt.get<LocalImageProviderService>().searchDir(Uri.parse(widget._path)).where((event) => !event.isDirectory).listen((file) {
      setState((){
        print("updating list state"); 
        DateTime lastModified = file.lastModified;
        DateTime date = DateTime(lastModified.year, lastModified.month, lastModified.day);  

        if(!this._dates.contains(date)) {
          this._dates.add(date);
          this._dates.sort((date1, date2) => date2.compareTo(date1));
        }

        String key = this._createKey(date);
        _sortedFiles.putIfAbsent(key, () => []);
        _sortedFiles[key].add(file);
      });
    });
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
              return Image.file(_sortedFiles[key][index].localFile, cacheWidth: 64, key: ValueKey(_sortedFiles[key][index].uri.path),);
            },
            childCount: _sortedFiles[key].length
          ), 
          gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 100.0,
            mainAxisSpacing: 2.0,
            crossAxisSpacing: 2.0,
            childAspectRatio: 1.0,
          )
        )
      ));
    });
    
    return CustomScrollView(
      slivers: slivers,
    );
  }
}