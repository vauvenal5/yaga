import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:yaga/utils/service_locator.dart';
import 'package:yaga/services/local_image_provider_service.dart';

class FolderWidget extends StatefulWidget {
  final String _path;
  final Function _onFolderTap;

  FolderWidget(this._path, this._onFolderTap);

  @override
  State<StatefulWidget> createState() => FolderWidgetState();
}

class FolderWidgetState extends State<FolderWidget> {
  List<FileSystemEntity> _files = [];
  List<FileSystemEntity> _folders = [];

  void _updateFilesAndFolders() {
    this._files = [];
    this._folders = [];

    getIt.get<LocalImageProviderService>().searchDir(widget._path).listen((file) {
      setState((){
        print("updating list state");
        if(file is File) {
          print(file.lastModifiedSync().toString());
          // readExifFromBytes(file.readAsBytesSync()).asStream().listen((event) {
          //   print(event);
          // });
          _files.add(file);
        } else {
          _folders.add(file);
        }
      });
    });
  }

  @override
  void initState() {
    super.initState();
    this._updateFilesAndFolders();
  }
  

  @override
  void didUpdateWidget(FolderWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    this._updateFilesAndFolders();
  }

  @override
  Widget build(BuildContext context) {
    print("drawing list");
    // return ListView(children: StreamBuilder<Widget>(),)
    
    return CustomScrollView(
      slivers: <Widget>[
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => ListTile(
              leading: Icon(Icons.folder, size: 32,),
              title: Text(_folders[index].uri.toString()),
              onTap: () => widget._onFolderTap(_folders[index]),
            ),
            childCount: _folders.length
          )
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => ListTile(
              leading: Image.file(_files[index], cacheWidth: 32,),
              title: Text(_files[index].uri.toString()),
            ),
            childCount: _files.length
          )
        ),
      ],
    );
  }
}