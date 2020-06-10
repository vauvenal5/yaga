import 'package:rxdart/rxdart.dart';
import 'package:flutter/material.dart';
import 'package:yaga/managers/file_manager.dart';
import 'package:yaga/model/nc_file.dart';
import 'package:yaga/utils/service_locator.dart';

class RemoteImageWidget extends StatelessWidget {
  final NcFile _file;

  RemoteImageWidget(this._file) {
    this._file.localFile.exists().asStream()
    .doOnData((event) => print("Event:$event"))
    .where((event) => !event)
    .flatMap((value) => this._file.previewFile.exists().asStream().where((exists) => !exists))
    .listen((event) => getIt.get<FileManager>().downloadPreviewCommand(_file));
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<NcFile>(
      stream: getIt.get<FileManager>().updatePreviewCommand.where((event) => event.path == _file.path),
      initialData: this._file,
      builder: (context, snapshot) {
        if(snapshot.data.localFile != null && snapshot.data.localFile.existsSync()) {
          return Image.file(snapshot.data.localFile, cacheWidth: 128, cacheHeight: 128,);
        }

        if(snapshot.data.previewFile != null && snapshot.data.previewFile.existsSync()) {
          return Image.file(snapshot.data.previewFile, cacheWidth: 128, cacheHeight: 128,);
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