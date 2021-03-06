import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:share/share.dart';
import 'package:yaga/managers/file_manager.dart';
import 'package:yaga/model/fetched_file.dart';
import 'package:yaga/model/nc_file.dart';
import 'package:yaga/services/intent_service.dart';
import 'package:yaga/utils/download_file_image.dart';
import 'package:yaga/utils/forground_worker/messages/download_file_request.dart';
import 'package:yaga/utils/logger.dart';
import 'package:yaga/utils/service_locator.dart';

class ImageScreen extends StatefulWidget {
  static const String route = "/image";
  final List<NcFile> _images;
  final int index;
  final String title;

  ImageScreen(
    this._images,
    this.index, {
    this.title,
  });

  @override
  State<StatefulWidget> createState() => ImageScreenState();
}

class ImageScreenState extends State<ImageScreen> {
  final _logger = YagaLogger.getLogger(ImageScreenState);
  String _title;
  int _currentIndex;
  PageController pageController;

  @override
  void initState() {
    pageController = PageController(initialPage: widget.index);
    this._currentIndex = pageController.initialPage;
    this._title = widget._images[_currentIndex].name;
    super.initState();
  }

  void _onPageChanged(int index) {
    setState(() {
      this._currentIndex = index;
      this._title = widget._images[index].name;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title ?? _title),
        actions: <Widget>[_buildMainAction()],
      ),
      body: PhotoViewGallery.builder(
        pageController: pageController,
        onPageChanged: _onPageChanged,
        itemCount: widget._images.length,
        builder: (BuildContext context, int index) {
          NcFile image = widget._images[index];

          _logger.fine("Building view for index $index");

          Future<FetchedFile> localFileAvailable = getIt
              .get<FileManager>()
              .fetchedFileCommand
              .where((event) => event.file.uri.path == image.uri.path)
              .first;
          getIt.get<FileManager>().downloadImageCommand(
                DownloadFileRequest(image),
              );

          return PhotoViewGalleryPageOptions(
            key: ValueKey(image.uri.path),
            minScale: PhotoViewComputedScale.contained,
            imageProvider: DownloadFileImage(
              image.localFile.file as File,
              localFileAvailable,
            ),
          );
        },
        loadingBuilder: (context, event) {
          bool previewExists =
              widget._images[_currentIndex].previewFile != null &&
                  widget._images[_currentIndex].previewFile.exists;
          return Stack(children: [
            Container(
              color: Colors.black,
              child: previewExists
                  ? Image.file(widget._images[_currentIndex].previewFile.file,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.contain)
                  : null,
            ),
            LinearProgressIndicator()
          ]);
        },
      ),
    );
  }

  IconButton _buildMainAction() {
    if (getIt.get<IntentService>().isOpenForSelect) {
      return IconButton(
        icon: Icon(Icons.check),
        onPressed: () async {
          await getIt
              .get<IntentService>()
              .setSelectedFile(widget._images[_currentIndex]);
        },
      );
    }

    return IconButton(
      icon: Icon(Icons.share),
      onPressed: () =>
          Share.shareFiles([widget._images[_currentIndex].localFile.file.path]),
    );
  }
}
