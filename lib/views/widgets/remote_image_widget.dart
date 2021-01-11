import 'dart:io';

import 'package:logger/logger.dart';
import 'package:rxdart/rxdart.dart';
import 'package:flutter/material.dart';
import 'package:yaga/managers/file_manager.dart';
import 'package:yaga/managers/isolateable/nextcloud_file_manger.dart';
import 'package:yaga/model/nc_file.dart';
import 'package:yaga/services/isolateable/nextcloud_service.dart';
import 'package:yaga/utils/forground_worker/bridges/nextcloud_manager_bridge.dart';
import 'package:yaga/utils/logger.dart';
import 'package:yaga/utils/service_locator.dart';
import 'package:yaga/views/widgets/circle_avatar_icon.dart';

class RemoteImageWidget extends StatelessWidget {
  final Logger _logger = getLogger(RemoteImageWidget, level: Level.warning);
  final NcFile _file;
  final int cacheWidth;
  final int cacheHeight;

  RemoteImageWidget(this._file, {Key key, this.cacheWidth, this.cacheHeight})
      : super(key: key);

  Widget _createIconOverlay(FileSystemEntity file, Widget iconWidget) {
    List<Widget> children = <Widget>[
      Ink.image(
        image: ResizeImage.resizeIfNeeded(
          cacheWidth,
          cacheHeight,
          FileImage(file),
        ),
        fit: BoxFit.cover,
      ),
      Align(
        alignment: Alignment.bottomRight,
        child: CircleAvatarIcon(icon: iconWidget),
      ),
    ];

    if (_file.selected) {
      children.add(Align(
        alignment: Alignment.topLeft,
        child: CircleAvatarIcon(
          icon: Icon(
            Icons.check,
            color: Colors.blue,
          ),
        ),
      ));
    }

    return Stack(
      fit: StackFit.expand,
      children: children,
    );
  }

  Widget _getLocalIcon(NcFile file, bool localExists, BuildContext context) {
    if (getIt.get<NextCloudService>().isUriOfService(file.uri)) {
      if (localExists) {
        return Icon(
          Icons.check_circle,
          color: Colors.green,
        );
      }
      return Icon(
        Icons.cloud_circle,
        color: Theme.of(context).accentColor,
      );
    }
    return Icon(
      Icons.phone_android,
      color: Colors.black,
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<NcFile>(
        stream: Rx.merge([
          getIt.get<NextcloudFileManager>().updatePreviewCommand,
          getIt.get<FileManager>().updateImageCommand
        ]).where((event) => event.uri.path == _file.uri.path),
        initialData: this._file,
        builder: (context, snapshot) {
          NcFile file = snapshot.data;
          bool localExists = file.localFile.existsSync();

          if (file.previewFile != null && file.previewFile.existsSync()) {
            return _createIconOverlay(
              snapshot.data.previewFile,
              _getLocalIcon(file, localExists, context),
            );
          } else {
            if (getIt.get<NextCloudService>().isUriOfService(_file.uri)) {
              getIt.get<NextcloudManagerBridge>().downloadPreviewCommand(_file);
            }
          }

          if (file.localFile != null && localExists) {
            return _createIconOverlay(
              snapshot.data.localFile,
              _getLocalIcon(file, localExists, context),
            );
          }

          return Container(
            height: 32,
            width: 32,
            child: CircularProgressIndicator(),
          );
        });
  }
}
