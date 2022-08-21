import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:rx_command/rx_command.dart';
import 'package:yaga/managers/nextcloud_manager.dart';
import 'package:yaga/model/fetched_file.dart';
import 'package:yaga/model/nc_file.dart';
import 'package:yaga/services/isolateable/local_file_service.dart';
import 'package:yaga/services/isolateable/nextcloud_service.dart';
import 'package:yaga/utils/background_worker/background_commands.dart';
import 'package:yaga/utils/background_worker/messages/background_download_request.dart';
import 'package:yaga/utils/background_worker/messages/background_downloaded_request.dart';
import 'package:yaga/utils/background_worker/messages/background_init_msg.dart';
import 'package:yaga/utils/forground_worker/messages/download_file_request.dart';
import 'package:yaga/utils/logger.dart';
import 'package:yaga/utils/self_signed_cert_handler.dart';
import 'package:yaga/utils/service_locator.dart';

class BackgroundWorker {
  final _logger = YagaLogger.getLogger(BackgroundWorker);
  final NextCloudManager _nextCloudManager;
  final SelfSignedCertHandler _selfSignedCertHandler;
  final service = FlutterBackgroundService();

  final RxCommand<FetchedFile, FetchedFile> isolateResponseCommand =
      RxCommand.createSync((param) => param);

  final Map<String, Function(BackgroundDownloadedRequest)> handlers = {};
  StreamSubscription? _initDoneSubscription;

  BackgroundWorker(this._nextCloudManager, this._selfSignedCertHandler);

  Future<BackgroundWorker> init() async {
    await service.configure(
      androidConfiguration: AndroidConfiguration(
        // this will be executed when app is in foreground or background in separated isolate
        onStart: _workerMain,
        // auto start service
        autoStart: false,
        isForegroundMode: true,
      ),
      iosConfiguration: IosConfiguration(
        // auto start service
        autoStart: false,
        // this will be executed when app is in foreground in separated isolate
        onForeground: _workerMain,
        // you have to enable background fetch capability on xcode project
        onBackground: _onIosBackground,
      ),
    );

    service.on(BackgroundCommands.started).listen((event) {
      _logger.info("Started Message");
      service.invoke(
          BackgroundCommands.init,
          BackgroundInitMsg(
            _nextCloudManager.updateLoginStateCommand.lastResult!,
            _selfSignedCertHandler.fingerprint,
          ).toJson());
    });

    service.on(BackgroundCommands.fetched).listen((event) {
      if (event == null) {
        return;
      }

      final request = BackgroundDownloadedRequest.fromJson(event);

      _logger.info(
        "Fetched Message: success=${request.success} ${request.uri.toString()}",
      );

      handlers.remove(request.uri.toString())?.call(request);

      if (handlers.isEmpty) {
        _logger.info("Stop requested");
        service.invoke(BackgroundCommands.stop);
      }
    });

    return this;
  }

  Future<void> downloadFile(DownloadFileRequest fileRequest) async {
    final String ncFileIdentifier = fileRequest.file.uri.toString();

    _logger.info("Download request: $ncFileIdentifier");

    handlers[ncFileIdentifier] = (BackgroundDownloadedRequest event) async =>
        _fileFetchedHandler(event, fileRequest.file);

    if (await service.isRunning()) {
      _sendDownloadRequest(fileRequest.file);
      return;
    }

    //double check old init subscription was canceled
    await _initDoneSubscription?.cancel();
    _initDoneSubscription = service.on(BackgroundCommands.initDone).listen(
      (event) {
        _logger.info("Inited Message: $ncFileIdentifier");
        // as soon as init is done, we do not need the subscription anymore
        _initDoneSubscription?.cancel();
        _sendDownloadRequest(fileRequest.file);
      },
    );

    await service.startService();
  }

  void _sendDownloadRequest(NcFile file) {
    service.invoke(
      BackgroundCommands.download,
      BackgroundDownloadRequest(
        uri: file.uri,
        localFileUri: file.localFile!.file.uri,
        lastModified: file.lastModified!,
      ).toJson(),
    );
  }

  Future<void> _fileFetchedHandler(
      BackgroundDownloadedRequest event, NcFile ncFile) async {
    if (!event.success) {
      //todo: Background: add notification or something
      return;
    }

    final File file = File.fromUri(event.localFileUri);
    ncFile.localFile!.file = file;
    ncFile.localFile!.exists = true;

    isolateResponseCommand(
      FetchedFile(
        ncFile,
        await file.readAsBytes(),
      ),
    );
  }

  static bool _onIosBackground(ServiceInstance service) {
    return true;
  }

  static Future<void> _workerMain(ServiceInstance service) async {
    // Only available for flutter 3.0.0 and later
    DartPluginRegistrant.ensureInitialized();

    final ser = service as AndroidServiceInstance;
    final Map<String, BackgroundDownloadRequest> allActive = {};

    service.on(BackgroundCommands.init).listen((event) {
      if (event == null) {
        return;
      }

      final init = BackgroundInitMsg.fromJson(event);
      setupBackgroundServiceLocator(init);
      service.invoke(BackgroundCommands.initDone);
    });

    service.on(BackgroundCommands.download).listen(
          (event) => _handleDownload(
            ser,
            event,
            allActive,
          ),
        );

    service.on(BackgroundCommands.stop).listen((event) {
      if (allActive.isEmpty) {
        service.stopSelf();
      }
    });

    service.invoke(BackgroundCommands.started);
  }

  static Future<void> _handleDownload(
    AndroidServiceInstance service,
    Map<String, dynamic>? event,
    Map<String, BackgroundDownloadRequest> allActive,
  ) async {
    if (event == null) {
      return;
    }

    final request = BackgroundDownloadRequest.fromJson(event);

    allActive[request.uri.toString()] = request;

    await _updateNotification(service, allActive.values.toList());

    getIt.allReady().then((_) {
      getIt
          .get<NextCloudService>()
          .downloadImage(request.uri)
          .then((value) async {
        await getIt.get<LocalFileService>().createFile(
              file: File.fromUri(request.localFileUri),
              bytes: value,
              lastModified: request.lastModified,
            );

        await _handleResult(
          service: service,
          request: request,
          allActive: allActive,
          success: true,
        );
      }).catchError((error) async {
        await _handleResult(
          service: service,
          request: request,
          allActive: allActive,
          success: false,
        );
      });
    });
  }

  static Future<void> _handleResult({
    required AndroidServiceInstance service,
    required BackgroundDownloadRequest request,
    required Map<String, BackgroundDownloadRequest> allActive,
    required bool success,
  }) async {
    service.invoke(
      BackgroundCommands.fetched,
      BackgroundDownloadedRequest(
        success: success,
        request: request,
      ).toJson(),
    );
    allActive.remove(request.uri.toString());
    await _updateNotification(service, allActive.values.toList());
  }

  static Future<void> _updateNotification(
    AndroidServiceInstance service,
    List<BackgroundDownloadRequest> allActive,
  ) {
    String names = "...";

    if (allActive.isNotEmpty) {
      names = allActive.map((e) => e.uri.pathSegments.last).reduce(
            (value, element) => value += ", $element",
          );
    }

    return service.setForegroundNotificationInfo(
      title: "Nextcloud Yaga",
      content: "Downloading $names",
    );
  }
}
