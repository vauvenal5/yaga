import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:yaga/managers/file_manager.dart';
import 'package:yaga/model/nc_file.dart';
import 'package:yaga/utils/service_locator.dart';

class ImageScreen extends StatelessWidget {
  static const String route = "/image";
  final NcFile _image;

  ImageScreen(this._image) {
    this._image.localFile.exists().asStream()
    .where((event) => !event)
    .listen((event) => getIt.get<FileManager>().downloadImageCommand(_image));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<NcFile>(
        stream: getIt.get<FileManager>().updateImageCommand.where((event) => event.uri.path == _image.uri.path),
        initialData: this._image,
        builder: (context, snapshot) {
          if(snapshot.data.localFile != null && snapshot.data.localFile.existsSync()) {
            return PhotoView(imageProvider: FileImage(snapshot.data.localFile));
          }

          if(snapshot.data.previewFile != null && snapshot.data.previewFile.existsSync()) {
            return PhotoView(imageProvider: FileImage(snapshot.data.previewFile));
          }

          return Container(
            height: 32,
            width: 32,
            child: CircularProgressIndicator(),
          );
        }
      )
      // body: PhotoView(imageProvider: FileImage(this._image.previewFile)),
    );
  }
}