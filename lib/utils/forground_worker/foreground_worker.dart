import 'dart:async';
import 'dart:isolate';

import 'package:rx_command/rx_command.dart';
import 'package:yaga/managers/global_settings_manager.dart';
import 'package:yaga/managers/nextcloud_manager.dart';
import 'package:yaga/services/isolateable/system_location_service.dart';
import 'package:yaga/services/shared_preferences_service.dart';
import 'package:yaga/utils/forground_worker/isolate_handler_regestry.dart';
import 'package:yaga/utils/forground_worker/messages/flush_logs_message.dart';
import 'package:yaga/utils/forground_worker/messages/init_msg.dart';
import 'package:yaga/utils/forground_worker/messages/message.dart';
import 'package:yaga/utils/logger.dart';
import 'package:yaga/utils/self_signed_cert_handler.dart';
import 'package:yaga/utils/service_locator.dart';

class ForegroundWorker {
  final _logger = YagaLogger.getLogger(ForegroundWorker);

  Isolate? _isolate;
  SendPort? _mainToIsolate;
  Completer<ForegroundWorker> _isolateReady = Completer<ForegroundWorker>();

  final NextCloudManager _nextCloudManager;
  final GlobalSettingsManager _globalSettingsManager;
  final SelfSignedCertHandler _selfSignedCertHandler;
  final SharedPreferencesService _sharedPreferencesService;
  final SystemLocationService _systemLocationService;

  RxCommand<Message, Message> isolateResponseCommand =
      RxCommand.createSync((param) => param);

  ForegroundWorker(
    this._nextCloudManager,
    this._globalSettingsManager,
    this._selfSignedCertHandler,
    this._sharedPreferencesService,
    this._systemLocationService,
  );

  Future<ForegroundWorker> get isolateReadyFuture => _isolateReady.future;

  Future<ForegroundWorker> init() async {
    final isolateToMain = ReceivePort();

    isolateToMain.listen((message) {
      if (message is SendPort) {
        _mainToIsolate = message;
        _isolateReady.complete(this);
        return;
      }

      if (message is List) {
        _logger.severe("Error in forground worker: ${message[0]}", null,
            StackTrace.fromString(message[1].toString()));
      }

      if (message is Message) {
        _logger.info("Main received: $message");
        isolateResponseCommand(message);
      }
    });

    _isolate = await Isolate.spawn(
      _workerMain,
      InitMsg(
        isolateToMain.sendPort,
        (await _systemLocationService.getExternal())!,
        await _systemLocationService.getCacheDir(),
        (await _systemLocationService.getExternals())!,
        _nextCloudManager.updateLoginStateCommand.lastResult!,
        _globalSettingsManager.updateRootMappingPreference.lastResult,
        _selfSignedCertHandler.fingerprint,
        _sharedPreferencesService.loadPreferenceFromBool(
          GlobalSettingsManager.autoPersist,
        ),
      ),
      errorsAreFatal: false,
      onError: isolateToMain.sendPort,
    );

    return isolateReadyFuture;
  }

  void dispose() {
    _isolateReady = Completer<ForegroundWorker>();
    _isolate?.kill();
  }

  void sendRequest(Message request) {
    if(_isolateReady.isCompleted) {
      _mainToIsolate?.send(request);
    } else {
      isolateReadyFuture.then((value) => _mainToIsolate?.send(request));
    }
  }

  static Future<void> _workerMain(dynamic message) async {
    SendPort? isolateToMain;
    final mainToIsolate = ReceivePort();
    final handlerRegistry = IsolateHandlerRegistry();
    final _logger = YagaLogger.getLogger(ForegroundWorker);

    if (message is InitMsg) {
      isolateToMain = message.sendPort;
      await YagaLogger.init(isolate: true);
      setupIsolatedServiceLocator(message, isolateToMain, handlerRegistry);
      getIt.allReady().then((value) {
        isolateToMain?.send(mainToIsolate.sendPort);
      });
    }

    mainToIsolate.listen((message) async {
      if (message is FlushLogsMessage) {
        await YagaLogger.fileHandler.flushFile();
        isolateToMain?.send(FlushLogsMessage(flushed: true));
        return;
      }

      if (message is Message) {
        _logger.info("Isolate received: $message");
        handlerRegistry.handleMessage(message);
      }
    });
  }
}
