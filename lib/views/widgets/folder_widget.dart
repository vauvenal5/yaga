import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:yaga/managers/file_manager.dart';
import 'package:yaga/model/nc_file.dart';
import 'package:yaga/utils/service_locator.dart';
import 'package:yaga/views/widgets/remote_image_widget.dart';

class FolderWidget extends StatefulWidget {
  final Uri _uri;
  final Function _onFolderTap;

  FolderWidget(this._uri, this._onFolderTap);

  @override
  State<StatefulWidget> createState() => FolderWidgetState();
}

class FolderWidgetState extends State<FolderWidget> {
  List<NcFile> _files = [];
  List<NcFile> _folders = [];
  StreamSubscription<NcFile> _updateFilesListCommandSubscription;
  bool _loading;

  @override
  void dispose() {
    _updateFilesListCommandSubscription?.cancel();
    super.dispose();
  }

  void _updateFilesAndFolders() {
    this._files = [];
    this._folders = [];

    setState(() {
      _loading = true;
    });

    this._updateFilesListCommandSubscription?.cancel();
    
    this._updateFilesListCommandSubscription = getIt.get<FileManager>().listFiles(widget._uri)
    .listen(
      (file) {
        setState((){
          if(!file.isDirectory) {
            _files.add(file);
          } else {
            _folders.add(file);
          }
        });
      },
      onDone: () => setState((){
        _loading=false;
        _folders.sort((a,b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        _files.sort((a,b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      })
    );
  }

  @override
  void initState() {
    this._updateFilesAndFolders();
    super.initState();
  }
  

  @override
  void didUpdateWidget(FolderWidget oldWidget) {
    this._updateFilesAndFolders();
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    print("drawing list");
    // return ListView(children: StreamBuilder<Widget>(),)
    
    return Stack(
      children: [
        CustomScrollView(
          slivers: <Widget>[
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => ListTile(
                  leading: Icon(Icons.folder, size: 32,),
                  title: Text(_folders[index].name),
                  onTap: () => widget._onFolderTap(_folders[index]),
                ),
                childCount: _folders.length
              )
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => ListTile(
                  leading: RemoteImageWidget(_files[index], key: ValueKey(_files[index].uri.path), cacheWidth: 128, cacheHeight: 128,),
                  // _files[index].localFile==null ?
                  //   Image.memory(_files[index].inMemoryPreview, cacheWidth: 32,) : 
                  //   Image.file(_files[index].localFile, cacheWidth: 32,),
                  title: Text(_files[index].name),
                ),
                childCount: _files.length
              )
            ),
          ],
        ),
        _loading ? LinearProgressIndicator() : Container()
      ],
    );
  }
}