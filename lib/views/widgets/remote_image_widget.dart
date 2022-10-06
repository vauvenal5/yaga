import 'dart:io';

import 'package:flutter_svg/flutter_svg.dart';
import 'package:rxdart/rxdart.dart';
import 'package:flutter/material.dart';
import 'package:yaga/managers/file_manager/file_manager.dart';
import 'package:yaga/managers/file_service_manager/isolateable/nextcloud_file_manger.dart';
import 'package:yaga/model/nc_file.dart';
import 'package:yaga/services/isolateable/nextcloud_service.dart';
import 'package:yaga/utils/forground_worker/bridges/nextcloud_manager_bridge.dart';
import 'package:yaga/utils/nextcloud_colors.dart';
import 'package:yaga/utils/service_locator.dart';
import 'package:yaga/views/widgets/circle_avatar_icon.dart';

class RemoteImageWidget extends StatelessWidget {
  final NcFile _file;
  final int cacheWidth;
  final int? cacheHeight;
  final bool showFileEnding;

  const RemoteImageWidget(
    this._file, {
    Key? key,
    required this.cacheWidth,
    this.cacheHeight,
    this.showFileEnding = true,
  }) : super(key: key);

  Widget _createIconOverlay(BuildContext context, Ink mainWidget) {
    final List<Widget> children = <Widget>[
      mainWidget,
      Align(
        alignment: Alignment.bottomRight,
        child: CircleAvatarIcon(icon: _getLocalIcon(context)),
      ),
    ];

    if (_file.selected) {
      children.add(const Align(
        alignment: Alignment.topLeft,
        child: CircleAvatarIcon(
          icon: Icon(
            Icons.check,
            color: NextcloudColors.lightBlue,
          ),
        ),
      ));
    }

    return Stack(
      fit: StackFit.expand,
      children: children,
    );
  }

  Ink _inkFromImage(FileSystemEntity file) => Ink.image(
        image: ResizeImage.resizeIfNeeded(
          cacheWidth,
          cacheHeight,
          FileImage(file as File),
        ),
        fit: BoxFit.cover,
      );

  Icon _getLocalIcon(BuildContext context) {
    if (getIt.get<NextCloudService>().isUriOfService(_file.uri)) {
      if (_file.localFile!.exists) {
        return const Icon(
          Icons.check_circle,
          color: Colors.green,
        );
      }
      return Icon(
        Icons.cloud_circle,
        color: Theme.of(context).accentColor,
      );
    }
    return const Icon(
      Icons.phone_android,
      color: Colors.black,
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<NcFile>(
      stream: Rx.merge([
        getIt
            .get<NextcloudFileManager>()
            .updatePreviewCommand
            .where((event) => event.uri.path == _file.uri.path)
            //here we are backpropagating the existing flag to the local file list
            //this is okay since we do not need to do any imediate action upon this change just have the value in case of resorting
            .doOnData(
              (event) => _file.previewFile = event.previewFile,
            ),
        getIt
            .get<FileManager>()
            .updateImageCommand
            .where((event) => event.uri.path == _file.uri.path)
            //here we are backpropagating the existing flag to the local file list
            //this is okay since we do not need to do any imediate action upon this change just have the value in case of resorting
            .doOnData(
              (event) => _file.localFile = event.localFile,
            )
      ]),
      initialData: _file,
      builder: (context, snapshot) {
        if (_file.previewFile != null && _file.previewFile!.exists) {
          return _createIconOverlay(
            context,
            _inkFromImage(snapshot.data!.previewFile!.file),
          );
        }

        _requestPreviewDownload();

        if (_file.localFile != null && _file.localFile!.exists) {
          return _createIconOverlay(
            context,
            _inkFromImage(snapshot.data!.localFile!.file),
          );
        }

        return _createDefaultIconPreview(context);
      },
    );
  }

  Widget _createDefaultIconPreview(BuildContext context) {
    final children = <Widget>[
      SvgPicture.asset(
        "assets/icon/foreground_no_border.svg",
        semanticsLabel: 'Yaga Logo',
        // alignment: Alignment.center,
        width: 48,
      ),
    ];

    if (showFileEnding) {
      children.add(Text(_file.fileExtension));
    }

    return _createIconOverlay(
      context,
      Ink(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: children,
        ),
      ),
    );
  }

  void _requestPreviewDownload() {
    if (getIt.get<NextCloudService>().isUriOfService(_file.uri)) {
      getIt.get<NextcloudManagerBridge>().downloadPreviewCommand(_file);
    }
  }
}
