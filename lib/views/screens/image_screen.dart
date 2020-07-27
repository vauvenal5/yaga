import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:yaga/managers/file_manager.dart';
import 'package:yaga/model/nc_file.dart';
import 'package:yaga/utils/download_file_image.dart';
import 'package:yaga/utils/service_locator.dart';
import 'package:wc_flutter_share/wc_flutter_share.dart';

class ImageScreen extends StatefulWidget {
  static const String route = "/image";
  final List<NcFile> _images;
  final PageController pageController;
  final String title;

  ImageScreen(this._images, int index, {this.title}) : pageController = PageController(initialPage: index);

  @override
  State<StatefulWidget> createState() => ImageScreenState();
}

class ImageScreenState extends State<ImageScreen> {
  String _title;
  int _currentIndex;

  @override
  void initState() {
    this._currentIndex = widget.pageController.initialPage;
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
        title: Text(widget.title??_title),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.share), 
            onPressed: () => WcFlutterShare.share( //todo: dp we need to move this to a service or controller?
	            sharePopupTitle: 'share',
              fileName: widget._images[_currentIndex].name,
              mimeType: 'image/jpeg', //todo: get real mime type
              bytesOfFile: widget._images[_currentIndex].localFile.readAsBytesSync()
            ),
          )
        ],
      ),
      body: 
      Stack(
        children: [
          PhotoViewGallery.builder(
            pageController: widget.pageController,
            onPageChanged: _onPageChanged,
            itemCount: widget._images.length, 
            builder: (BuildContext context, int index) {
              NcFile image = widget._images[index];

              Future<File> localFileAvailable = Future.value(image.localFile);
              if(!image.localFile.existsSync()) {
                localFileAvailable = getIt.get<FileManager>().updateImageCommand
                  .where((event) => event.uri.path == image.uri.path)
                  .map((event) => event.localFile)
                  .first;
                getIt.get<FileManager>().downloadImageCommand(image);
              }

              return PhotoViewGalleryPageOptions(
                key: ValueKey(image.uri.path),
                minScale: PhotoViewComputedScale.contained,
                imageProvider: DownloadFileImage(image.localFile, localFileAvailable),
              );
            },
            loadingBuilder: (context, event) {
              bool previewExists = widget._images[_currentIndex].previewFile != null && widget._images[_currentIndex].previewFile.existsSync();
              return Stack(
                children: [
                  Container(
                    color: Colors.black,
                    child: previewExists ? Image.file(
                      widget._images[_currentIndex].previewFile, 
                      width: double.infinity, 
                      height: double.infinity, 
                      fit: BoxFit.contain
                    ) : null,
                  ),
                  LinearProgressIndicator()
                ]
              );
            },
          ),
        ]
      )
    );
  }

}