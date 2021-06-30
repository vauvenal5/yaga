import 'dart:io';

import 'package:flutter_svg/flutter_svg.dart';
import 'package:rxdart/rxdart.dart';
import 'package:flutter/material.dart';
import 'package:yaga/managers/file_manager.dart';
import 'package:yaga/managers/isolateable/nextcloud_file_manger.dart';
import 'package:yaga/model/nc_file.dart';
import 'package:yaga/services/isolateable/nextcloud_service.dart';
import 'package:yaga/utils/forground_worker/bridges/nextcloud_manager_bridge.dart';
import 'package:yaga/utils/nextcloud_colors.dart';
import 'package:yaga/utils/service_locator.dart';
import 'package:yaga/views/widgets/circle_avatar_icon.dart';

class RemoteImageWidgetOther extends StatelessWidget {
  final NcFile _file;
  final int cacheWidth;
  final int cacheHeight;
  final bool showFileEnding;

  const RemoteImageWidgetOther(
    this._file, {
    Key key,
    this.cacheWidth,
    this.cacheHeight,
    this.showFileEnding = true,
  }) : super(key: key);

  Widget _createIconOverlay(Ink mainWidget, Icon iconWidget) {
    final List<Widget> children = <Widget>[
      mainWidget,
      Align(
        alignment: Alignment.bottomRight,
        child: CircleAvatarIcon(icon: iconWidget),
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

  Icon _getLocalIcon(NcFile file, bool localExists, BuildContext context) {
    if (getIt.get<NextCloudService>().isUriOfService(file.uri)) {
      if (localExists) {
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
    // todo: clean up the future (from Future<object> to Future<bool>)
    return FutureBuilder(
      future: Future.value(_file.localFile != null)
          .then((value) => value ? _file.localFile.file.exists() : value),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return _createDefaultIconPreview(_file, false, context);
        }

        return _buildPreview(snapshot.data as bool);
      },
    );
  }

  Widget _buildPreview(bool localFileExists) {
    // todo: clean up the future (from Future<object> to Future<bool>)
    return FutureBuilder(
      future: Future.value(_file.previewFile != null).then(
          (value) => value ? _file.previewFile.file.exists() : value),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return _createDefaultIconPreview(
              _file, localFileExists, context);
        }

        if (snapshot.data as bool) {
          return _createPreview(context, localFileExists, _file);
        }

        return _buildLocal(context, localFileExists);
      },
    );
  }

  Widget _createPreview(
      BuildContext context, bool localFileExists, NcFile file) {
    return _createIconOverlay(
      _inkFromImage(file.previewFile.file),
      _getLocalIcon(file, localFileExists, context),
    );
  }

  Widget _buildLocal(BuildContext context, bool localFileExists) {
    return StreamBuilder<NcFile>(
      stream: Rx.merge([
        getIt.get<NextcloudFileManager>().updatePreviewCommand,
        getIt.get<FileManager>().updateImageCommand
      ]).where((event) => event.uri.path == _file.uri.path),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return _createPreview(context, localFileExists, snapshot.data);
        }

        _requestPreviewDownload();

        if (localFileExists) {
          return _createIconOverlay(
            _inkFromImage(_file.localFile.file),
            _getLocalIcon(_file, localFileExists, context),
          );
        }

        return _createDefaultIconPreview(_file, localFileExists, context);
      },
    );
  }

  Widget _createDefaultIconPreview(
      NcFile file, bool localExists, BuildContext context) {
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
      Ink(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: children,
        ),
      ),
      _getLocalIcon(file, localExists, context),
    );
  }

  void _requestPreviewDownload() {
    if (getIt.get<NextCloudService>().isUriOfService(_file.uri)) {
      getIt.get<NextcloudManagerBridge>().downloadPreviewCommand(_file);
    }
  }
}
