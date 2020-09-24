import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:yaga/model/nc_file.dart';
import 'package:yaga/model/preference.dart';
import 'package:yaga/views/widgets/remote_image_widget.dart';
import 'package:yaga/views/widgets/state_wrappers/category_image_state_wrapper.dart';

class FolderWidget extends StatefulWidget {
  final Uri _uri;
  final Function(NcFile) onFolderTap;
  final Function(List<NcFile>, int) onFileTap;

  FolderWidget(this._uri, {this.onFolderTap, this.onFileTap});

  @override
  State<StatefulWidget> createState() => FolderWidgetState();
}

class FolderWidgetState extends State<FolderWidget> {
  CategoryImageStateWrapper _imageStateWrapper;

  @override
  void dispose() {
    this._imageStateWrapper.dispose();
    super.dispose();
  }

  @override
  void initState() {
    //todo: clean up properties
    SectionPreference general = SectionPreference.route("browse", "general", "General");
    _imageStateWrapper = CategoryImageStateWrapper(
      widget._uri,
      BoolPreference.section(general, "recursiveLoad", "Load Recursively", false)
    );

    this._imageStateWrapper.updateFilesAndFolders();
    super.initState();
  }
  

  @override
  void didUpdateWidget(FolderWidget oldWidget) {
    this._imageStateWrapper.updateFilesAndFolders();
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    print("drawing list");
    // return ListView(children: StreamBuilder<Widget>(),)
    
    return Stack(
      children: [
        StreamBuilder<List<NcFile>>(
          initialData: [],
          stream: this._imageStateWrapper.filesChangedCommand,
          builder: (context, snapshot) {
            List<NcFile> files = [];
            List<NcFile> folders = [];

            snapshot.data.forEach((file) {
              if(file.isDirectory && !folders.contains(file)) {
                folders.add(file);
                folders.sort((a,b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
              }

              if(!file.isDirectory && !files.contains(file)) {
                files.add(file);
                files.sort((a,b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
              }
            });

            return CustomScrollView(
              slivers: <Widget>[
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => ListTile(
                      leading: Icon(Icons.folder, size: 32,),
                      title: Text(folders[index].name),
                      onTap: widget.onFolderTap != null ? () => widget.onFolderTap(folders[index]) : null,
                    ),
                    childCount: folders.length
                  )
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => ListTile(
                      leading: Container(
                        width: 64,
                        height: 64,
                        child: RemoteImageWidget(files[index], key: ValueKey(files[index].uri.path), cacheWidth: 128,),
                      ),
                      // _files[index].localFile==null ?
                      //   Image.memory(_files[index].inMemoryPreview, cacheWidth: 32,) : 
                      //   Image.file(_files[index].localFile, cacheWidth: 32,),
                      title: Text(files[index].name),
                      onTap: widget.onFileTap != null ? () => widget.onFileTap(files, index) : null,
                    ),
                    childCount: files.length
                  )
                ),
              ],
            );
          }
        )
        ,
        StreamBuilder<bool>(
          initialData: true,
          stream: this._imageStateWrapper.loadingChangedCommand,
          builder: (context, snapshot) => snapshot.data ? LinearProgressIndicator() : Container(),
        )
      ],
    );
  }
}