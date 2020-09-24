import 'package:logger/logger.dart';
import 'package:rxdart/rxdart.dart';
import 'package:flutter/material.dart';
import 'package:yaga/managers/file_manager.dart';
import 'package:yaga/model/nc_file.dart';
import 'package:yaga/services/nextcloud_service.dart';
import 'package:yaga/utils/logger.dart';
import 'package:yaga/utils/service_locator.dart';

class RemoteImageWidget extends StatelessWidget {
  final Logger _logger = getLogger(RemoteImageWidget);
  final NcFile _file;
  final int cacheWidth;
  final int cacheHeight;

  RemoteImageWidget(this._file, {Key key, this.cacheWidth, this.cacheHeight}) : super(key: key) {
    this._file.localFile.exists().asStream()
    .doOnData((localFileExists) => _logger.d("Local file exists: $localFileExists (${_file.localFile.path})"))
    //.where((event) => !event)
    .where((localFileExists) => this._file.previewFile != null)
    .flatMap((value) => this._file.previewFile.exists().asStream()
      .doOnData((event) => _logger.d("Preview file exists: $event (${_file.previewFile.path})"))
      .where((exists) => !exists))
    .listen((event) => getIt.get<FileManager>().downloadPreviewCommand(_file));
  }

  Widget _createIconOverlay(Widget imageWidget, Widget iconWidget) => Stack(
    fit: StackFit.expand,
    children: <Widget>[
      imageWidget,
      Align(
        alignment: Alignment.bottomRight,
        child: Stack(
          alignment: Alignment.center,
          children: <Widget>[
            CircleAvatar(radius: 13, backgroundColor: Colors.white,),
            iconWidget,
          ],
        )
      )
    ]
  );

  Widget _getLocalIcon(NcFile file, bool localExists, BuildContext context) {
    if(getIt.get<NextCloudService>().isUriOfService(file.uri)) {
      if(localExists) {
        return Icon(Icons.check_circle, color: Colors.green,);
      }
      return Icon(Icons.cloud_circle, color: Theme.of(context).accentColor,);
    }
    return Icon(Icons.phone_android, color: Colors.black,);
  }

  @override
  Widget build(BuildContext context) {

    return StreamBuilder<NcFile>(
      stream: Rx.merge([
        getIt.get<FileManager>().updatePreviewCommand,
        getIt.get<FileManager>().updateImageCommand
      ]).where((event) => event.uri.path == _file.uri.path),
      initialData: this._file,
      builder: (context, snapshot) {
        NcFile file = snapshot.data;
        bool localExists = file.localFile.existsSync();

        if(file.previewFile != null && file.previewFile.existsSync()) {
          Image imageWidget = Image.file(
            snapshot.data.previewFile, 
            cacheWidth: this.cacheWidth, 
            cacheHeight: this.cacheHeight, 
            fit: BoxFit.cover,
          );

          return _createIconOverlay(imageWidget, _getLocalIcon(file, localExists, context));
        }

        if(file.localFile != null && localExists) {
          Image imageWidget = Image.file(
            snapshot.data.localFile, 
            cacheWidth: this.cacheWidth, 
            cacheHeight: this.cacheHeight, 
            fit: BoxFit.cover,
          );

          return _createIconOverlay(imageWidget, _getLocalIcon(file, localExists, context));
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