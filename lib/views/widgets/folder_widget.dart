import 'dart:io';

import 'package:rxdart/rxdart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:yaga/managers/file_manager.dart';
import 'package:yaga/model/nc_file.dart';
import 'package:yaga/services/nextcloud_service.dart';
import 'package:yaga/utils/service_locator.dart';
import 'package:yaga/services/local_image_provider_service.dart';
import 'package:yaga/utils/uri_utils.dart';
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

  void _updateFilesAndFolders() {
    this._files = [];
    this._folders = [];

    //todo: this mess has to be solved differently; this was only a proof of concept
    // if(widget._path.startsWith("nc:")) {
    if(UriUtils.isNextCloudUri(widget._uri)) {
      // getIt.get<NextCloudService>().listFiles(widget._path.replaceFirst("nc:", ""))
      // .where((event) => !event.isDirectory)
      // .asyncMap((event) async {
      //   event.inMemoryPreview = await getIt.get<NextCloudService>().getPreview(event.path);
      //   return event;
      // })
      // .listen((file) {
      //   if(file.isDirectory) {
      //     setState(() {
      //       _folders.add(file);
      //     });
      //   } else {
      //     print("loading preview");
      //     setState(() {
      //       _files.add(file);
      //     });
      //   }
      // });
      getIt.get<NextCloudService>().listFiles(widget._uri.path)
      .flatMap((ncFile) => getIt.get<LocalImageProviderService>().getTmpFile(ncFile.uri.path).asStream()
        .map((event) {
          ncFile.previewFile = event;
          return ncFile;
        })
      )
      .flatMap((ncFile) => getIt.get<LocalImageProviderService>().getLocalFile(ncFile.uri.path).asStream()
        .map((event) {
          ncFile.localFile = event;
          return ncFile;
        })
      )
      // .doOnData((event) async {
      //   event.previewFile = await getIt.get<LocalImageProviderService>().getTmpFile(event.path);
      //   event.localFile = await getIt.get<LocalImageProviderService>().getLocalFile(event.path);
      // })
      .listen((file) {
        if(file.isDirectory) {
          _folders.add(file);
        } else {
          _files.add(file);
        }
      }, onDone: () => setState((){}));
    } else {
      getIt.get<LocalImageProviderService>().searchDir(widget._uri).listen((file) {
        setState((){
          // print("updating list state");
          // print(file.uri.toString());
          if(!file.isDirectory) {
            // print(file.lastModifiedSync().toString());
            // readExifFromBytes(file.readAsBytesSync()).asStream().listen((event) {
            //   print(event);
            // });
            // NcFile ncFile = NcFile();
            // ncFile.name = file.path.split("/").last;
            // ncFile.path = file.path;
            // ncFile.localFile = file;
            _files.add(file);
          } else {
            // NcFile folder = NcFile();
            // folder.isDirectory = true;
            // folder.name = file.path.split("/").last;
            // folder.path = file.path;
            _folders.add(file);
          }
        });
      });
    }
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
              title: Text(_folders[index].name),
              onTap: () => widget._onFolderTap(_folders[index]),
            ),
            childCount: _folders.length
          )
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => ListTile(
              leading: RemoteImageWidget(_files[index]),
              // _files[index].localFile==null ?
              //   Image.memory(_files[index].inMemoryPreview, cacheWidth: 32,) : 
              //   Image.file(_files[index].localFile, cacheWidth: 32,),
              title: Text(_files[index].name),
            ),
            childCount: _files.length
          )
        ),
      ],
    );
  }
}