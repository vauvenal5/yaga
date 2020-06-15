import 'package:rxdart/rxdart.dart';
import 'package:flutter/material.dart';
import 'package:yaga/managers/file_manager.dart';
import 'package:yaga/model/nc_file.dart';
import 'package:yaga/utils/service_locator.dart';

class RemoteImageWidget extends StatelessWidget {
  final NcFile _file;
  final int cacheWidth;
  final int cacheHeight;

  RemoteImageWidget(this._file, {Key key, this.cacheWidth, this.cacheHeight}) : super(key: key) {
    this._file.localFile.exists().asStream()
    .doOnData((event) => print("Event:$event"))
    .where((event) => !event)
    .flatMap((value) => this._file.previewFile.exists().asStream().where((exists) => !exists))
    .listen((event) => getIt.get<FileManager>().downloadPreviewCommand(_file));
  }

  @override
  Widget build(BuildContext context) {

    return StreamBuilder<NcFile>(
      stream: getIt.get<FileManager>().updatePreviewCommand.where((event) => event.uri.path == _file.uri.path),
      initialData: this._file,
      builder: (context, snapshot) {
        NcFile file = snapshot.data;

        if(file.previewFile != null && file.previewFile.existsSync()) {
          return Image.file(
            snapshot.data.previewFile, 
            cacheWidth: this.cacheWidth, 
            cacheHeight: this.cacheHeight, 
            fit: BoxFit.cover,
          );
        }

        if(file.localFile != null && file.localFile.existsSync()) {
          return Image.file(
            snapshot.data.localFile, 
            cacheWidth: this.cacheWidth, 
            cacheHeight: this.cacheHeight, 
            fit: BoxFit.cover,
          );
        }

        return Container(
          height: 32,
          width: 32,
          child: CircularProgressIndicator(),
        );
      }
    );
  }
}