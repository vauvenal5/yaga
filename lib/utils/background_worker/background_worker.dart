import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:rx_command/rx_command.dart';
import 'package:yaga/managers/file_manager/isolateable/file_action_manager.dart';
import 'package:yaga/managers/nextcloud_manager.dart';
import 'package:yaga/model/fetched_file.dart';
import 'package:yaga/utils/background_worker/background_channel.dart';
import 'package:yaga/utils/background_worker/background_commands.dart';
import 'package:yaga/utils/background_worker/json_convertable.dart';
import 'package:yaga/utils/background_worker/messages/background_downloaded_request.dart';
import 'package:yaga/utils/background_worker/messages/background_init_msg.dart';
import 'package:yaga/utils/background_worker/work_tracker.dart';
import 'package:yaga/utils/forground_worker/messages/download_file_request.dart';
import 'package:yaga/utils/forground_worker/messages/file_update_msg.dart';
import 'package:yaga/utils/forground_worker/messages/files_action/delete_files_request.dart';
import 'package:yaga/utils/forground_worker/messages/files_action/destination_action_files_request.dart';
import 'package:yaga/utils/forground_worker/messages/files_action/favorite_files_request.dart';
import 'package:yaga/utils/forground_worker/messages/files_action/files_action_done.dart';
import 'package:yaga/utils/forground_worker/messages/files_action/files_action_request.dart';
import 'package:yaga/utils/forground_worker/messages/image_update_msg.dart';
import 'package:yaga/utils/forground_worker/messages/message.dart';
import 'package:yaga/utils/logger.dart';
import 'package:yaga/utils/self_signed_cert_handler.dart';
import 'package:yaga/utils/service_locator.dart';

class BackgroundWorker {
  final _logger = YagaLogger.getLogger(BackgroundWorker);
  final NextCloudManager _nextCloudManager;
  final SelfSignedCertHandler _selfSignedCertHandler;
  final service = FlutterBackgroundService();

  Completer<BackgroundWorker> _isolateReady = Completer<BackgroundWorker>();

  final RxCommand<Message, Message> isolateResponseCommand = RxCommand.createSync((param) => param);

  BackgroundWorker(this._nextCloudManager, this._selfSignedCertHandler);

  Future<BackgroundWorker> init() async {
    if (Platform.isAndroid) {
      await Permission.notification.request();
      await Permission.scheduleExactAlarm.request();
      await Permission.photos.request();
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

      service.on(BackgroundCommands.workerToMain).listen((json) async {
        if (json != null && json[JsonConvertable.jsonTypeField] != null) {
          final type = json[JsonConvertable.jsonTypeField] as String;

          switch (type) {
            case BackgroundDownloadedRequest.jsonTypeConst:
              _fileFetchedHandler(json);
              break;
            case FileUpdateMsg.jsonTypeConst:
              isolateResponseCommand(FileUpdateMsg.fromJson(json));
              break;
            case ImageUpdateMsg.jsonTypeConst:
              isolateResponseCommand(ImageUpdateMsg.fromJson(json));
              break;
            case FilesActionDone.jsonTypeConst:
              isolateResponseCommand(FilesActionDone.fromJson(json));
              break;
            default:
              //todo: handle error
              return;
          }
        }
      });

      service.on(BackgroundCommands.started).listen((event) {
        _logger.info("Started Message");
        service.invoke(
            BackgroundCommands.init,
            BackgroundInitMsg(
              _nextCloudManager.updateLoginStateCommand.lastResult!,
              _selfSignedCertHandler.fingerprint,
            ).toJson());
      });

      service.on(BackgroundCommands.initDone).listen(
        (event) {
          _logger.info("Init Done Message");
          _isolateReady.complete(this);
        },
      );

      service.on(BackgroundCommands.stopped).listen((event) {
        _isolateReady = Completer<BackgroundWorker>();
      });
    }
    return this;
  }

  Future<void> sendRequest(JsonConvertable message) async {
    _logger.info("Worker Request: ${message.jsonType}");

    if (await service.isRunning() && _isolateReady.isCompleted) {
      service.invoke(
        BackgroundCommands.mainToWorker,
        message.toJson(),
      );
      return;
    }

    _isolateReady.future.then(
      (value) => service.invoke(
        BackgroundCommands.mainToWorker,
        message.toJson(),
      ),
    );

    await service.startService();
  }

  Future<void> _fileFetchedHandler(Map<String, dynamic> json) async {
    final event = BackgroundDownloadedRequest.fromJson(json);

    _logger.info(
      "Fetched Message: success=${event.success} ${event.file.uri.toString()}",
    );

    if (!event.success) {
      //todo: Background: add notification or something
      return;
    }

    isolateResponseCommand(
      FetchedFile(
        event.file,
        await (event.file.localFile!.file as File).readAsBytes(),
      ),
    );
  }

  static bool _onIosBackground(ServiceInstance service) {
    return true;
  }

  @pragma('vm:entry-point')
  static Future<void> _workerMain(ServiceInstance service) async {
    // Only available for flutter 3.0.0 and later
    DartPluginRegistrant.ensureInitialized();

    final ser = service as AndroidServiceInstance;

    service.on(BackgroundCommands.init).listen((event) {
      if (event == null) {
        return;
      }

      final init = BackgroundInitMsg.fromJson(event);
      final channel = BackgroundChannel(ser);
      setupBackgroundServiceLocator(init, channel);
      getIt.allReady().then(
        (_) {
          getIt.get<FileActionManager>().filesActionDoneCommand.listen(
                (value) => service.invoke(BackgroundCommands.workerToMain, value.toJson()),
              );

          getIt.get<FileActionManager>().fileUpdateMessage.listen(
                (value) => service.invoke(BackgroundCommands.workerToMain, value.toJson()),
              );

          service.invoke(BackgroundCommands.initDone);
        },
      );
    });

    service.on(BackgroundCommands.mainToWorker).listen((event) {
      if (event == null || event[JsonConvertable.jsonTypeField] == null) {
        //todo: check for stop condition
        return;
      }

      final type = event[JsonConvertable.jsonTypeField] as String;

      switch (type) {
        case DownloadFileRequest.jsonTypeConst:
          _handleDownload(ser, DownloadFileRequest.fromJson(event));
        case DestinationActionFilesRequest.jsonTypeConst:
          _handleFileAction(
            ser,
            DestinationActionFilesRequest.fromJson(event),
            getIt.get<FileActionManager>().copyMoveRequest,
          );
        case DeleteFilesRequest.jsonTypeConst:
          _handleFileAction(
            ser,
            DeleteFilesRequest.fromJson(event),
            getIt.get<FileActionManager>().deleteFiles,
          );
        case FavoriteFilesRequest.jsonTypeConst:
          _handleFileAction(
            ser,
            FavoriteFilesRequest.fromJson(event),
            (msg) => getIt.get<FileActionManager>().toggleFavorites(msg),
          );
        default:
          //todo: log error
          //todo: check for stop condition
          return;
      }
    });

    service.invoke(BackgroundCommands.started);
  }

  static Future<void> _handleFileAction<T extends FilesActionRequest>(
    AndroidServiceInstance service,
    T message,
    Future<void> Function(T) handler,
  ) async {
    //todo: not unique enough; just temp
    getIt.get<WorkTracker>().activeTasks[message.sourceDir.toString()] = message;
    return handler(message).whenComplete(
      () => _checkAndStopService(
        service,
        message.sourceDir.toString(),
      ),
    );
  }

  static Future<void> _checkAndStopService(
    AndroidServiceInstance service,
    String taskId,
  ) async {
    getIt.get<WorkTracker>().activeTasks.remove(taskId);

    if (getIt.get<WorkTracker>().activeTasks.isEmpty) {
      service.invoke(BackgroundCommands.stopped);
      await service.stopSelf();
    }
  }

  static Future<void> _handleDownload(
    AndroidServiceInstance service,
    DownloadFileRequest request,
  ) async {
    getIt.get<WorkTracker>().activeTasks[request.file.uri.toString()] = request;

    await _updateNotification(service);

    return getIt
        .get<FileActionManager>()
        .downloadFile(request.file, persist: request.persist)
        .then((value) => _handleResult(
              service: service,
              request: request,
              success: true,
            ))
        .onError((error, stackTrace) => _handleResult(service: service, request: request, success: false));
  }

  static Future<void> _handleResult({
    required AndroidServiceInstance service,
    required DownloadFileRequest request,
    required bool success,
  }) async {
    service.invoke(
      BackgroundCommands.workerToMain,
      BackgroundDownloadedRequest(
        success: success,
        file: request.file,
      ).toJson(),
    );
    await _updateNotification(service);
    return _checkAndStopService(service, request.file.uri.toString());
  }

  static Future<void> _updateNotification(
    AndroidServiceInstance service,
  ) {
    String names = "...";

    //todo: fix message
    return service.setForegroundNotificationInfo(
      title: "Nextcloud Yaga",
      content: "Downloading $names",
    );
  }
}
