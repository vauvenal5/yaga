import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:share_plus/share_plus.dart';
import 'package:wakelock/wakelock.dart';
import 'package:yaga/managers/file_manager/file_manager.dart';
import 'package:yaga/managers/global_settings_manager.dart';
import 'package:yaga/model/fetched_file.dart';
import 'package:yaga/model/nc_file.dart';
import 'package:yaga/services/intent_service.dart';
import 'package:yaga/services/shared_preferences_service.dart';
import 'package:yaga/utils/download_file_image.dart';
import 'package:yaga/utils/forground_worker/messages/download_file_request.dart';
import 'package:yaga/utils/logger.dart';
import 'package:yaga/utils/service_locator.dart';

class ImageScreen extends StatefulWidget {
  static const String route = "/image";
  final List<NcFile> _images;
  final int index;
  final String? title;

  const ImageScreen(
    this._images,
    this.index, {
    this.title,
  });

  @override
  State<StatefulWidget> createState() => ImageScreenState();
}

class ImageScreenState extends State<ImageScreen> {
  final _logger = YagaLogger.getLogger(ImageScreenState);
  late String _title;
  late int _currentIndex;
  late PageController pageController;
  var _showAppBar = true;
  Timer? _timer;
  final rng = Random();

  @override
  void initState() {
    pageController = PageController(initialPage: widget.index);
    _currentIndex = pageController.initialPage;
    _title = widget._images[_currentIndex].name;
    super.initState();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
      _title = widget._images[index].name;
    });
  }

  @override
  void dispose() {
    _stopSlideShow();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: SystemUiOverlay.values);
    super.dispose();
  }

  void _stopSlideShow() {
    Wakelock.disable();
    _timer?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _showAppBar
          ? AppBar(
              title: Text(widget.title ?? _title),
              actions: _buildMainAction(context),
            )
          : null,
      body: GestureDetector(
        onTap: () => setState(() {
          _showAppBar = !_showAppBar;
          _showAppBar
              ? SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
                  overlays: SystemUiOverlay.values)
              : SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
        }),
        child: PhotoViewGallery.builder(
          pageController: pageController,
          onPageChanged: _onPageChanged,
          itemCount: widget._images.length,
          builder: (BuildContext context, int index) {
            final NcFile image = widget._images[index];

            _logger.fine("Building view for index $index");

            final Future<FetchedFile> localFileAvailable = getIt
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
                image.localFile!.file as File,
                localFileAvailable,
              ),
            );
          },
          loadingBuilder: (context, event) {
            final bool previewExists =
                widget._images[_currentIndex].previewFile != null &&
                    widget._images[_currentIndex].previewFile!.exists;
            return Stack(children: [
              Container(
                color: Colors.black,
                child: previewExists
                    ? Image.file(
                        widget._images[_currentIndex].previewFile!.file as File,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.contain)
                    : null,
              ),
              const LinearProgressIndicator()
            ]);
          },
        ),
      ),
    );
  }

  int _calculatePage(BuildContext context) {
    if(getIt.get<SharedPreferencesService>().loadPreferenceFromBool(GlobalSettingsManager.slideShowRandom).value) {
      return rng.nextInt(widget._images.length);
    }

    if(widget._images.length == _currentIndex + 1) {
      if(getIt.get<SharedPreferencesService>().loadPreferenceFromBool(GlobalSettingsManager.slideShowAutoStop).value) {
        _stopSlideShow();
        Navigator.pop(context);
      }
      return 0;
    }

    return _currentIndex + 1;
  }

  List<Widget> _buildMainAction(BuildContext context) {
    if (getIt.get<IntentService>().isOpenForSelect) {
      return [
        IconButton(
          icon: const Icon(Icons.check),
          onPressed: () async {
            await getIt
                .get<IntentService>()
                .setSelectedFile(widget._images[_currentIndex]);
          },
        ),
      ];
    }

    return [
      if (_timer == null)
        IconButton(
          icon: const Icon(Icons.play_circle_outline),
          onPressed: ()
          {
            Wakelock.enable();
            setState(
              () => _timer = Timer.periodic(
                Duration(
                  seconds: getIt
                      .get<SharedPreferencesService>()
                      .loadPreferenceFromInt(
                          GlobalSettingsManager.slideShowInterval)
                      .value,
                ),
                (Timer t) => pageController.jumpToPage(_calculatePage(context)),
              ),
            );
          },
        )
      else
        IconButton(
          icon: const Icon(Icons.stop_circle_outlined),
          onPressed: () {
            _stopSlideShow();
            setState(() => _timer = null);
          },
        ),
      IconButton(
        icon: const Icon(Icons.wallpaper),
        onPressed: () => getIt
            .get<IntentService>()
            .attachData(widget._images[_currentIndex]),
      ),
      IconButton(
        icon: const Icon(Icons.share),
        onPressed: () => Share.shareFiles(
            [widget._images[_currentIndex].localFile!.file.path]),
      ),
    ];
  }
}
