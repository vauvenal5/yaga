import 'dart:async';
import 'dart:isolate';

import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rx_command/rx_command.dart';
import 'package:yaga/managers/global_settings_manager.dart';
import 'package:yaga/managers/nextcloud_manager.dart';
import 'package:yaga/utils/forground_worker/isolate_handler_regestry.dart';
import 'package:yaga/utils/forground_worker/messages/init_msg.dart';
import 'package:yaga/utils/forground_worker/messages/message.dart';
import 'package:yaga/utils/logger.dart';
import 'package:yaga/utils/service_locator.dart';

class ForegroundWorker {
  final Logger _logger = getLogger(ForegroundWorker);

  Isolate _isolate;
  SendPort _mainToIsolate;
  Completer<ForegroundWorker> _isolateReady;

  final NextCloudManager _nextCloudManager;
  final GlobalSettingsManager _globalSettingsManager;

  RxCommand<Message, Message> isolateResponseCommand;

  ForegroundWorker(this._nextCloudManager, this._globalSettingsManager);

  Future<ForegroundWorker> init() async {
    _isolateReady = Completer<ForegroundWorker>();
    isolateResponseCommand = RxCommand.createSync((param) => param);
    final isolateToMain = ReceivePort();

    isolateToMain.listen((message) {
      if (message is SendPort) {
        this._mainToIsolate = message;
        _isolateReady.complete(this);
        return;
      }

      if (message is List) {
        _logger.e("Error in forground worker", message[0],
            StackTrace.fromString(message[1]));
      }

      if (message is Message) {
        isolateResponseCommand(message);
      }
    });

    this._isolate = await Isolate.spawn(
      _workerMain,
      InitMsg(
        isolateToMain.sendPort,
        await getExternalStorageDirectory(),
        await getTemporaryDirectory(),
        _nextCloudManager.updateLoginStateCommand.lastResult,
        _globalSettingsManager.updateRootMappingPreference.lastResult,
      ),
      errorsAreFatal: false,
      onError: isolateToMain.sendPort,
    );

    return _isolateReady.future;
  }

  void dispose() {
    _isolate.kill();
  }

  void sendRequest(Message request) {
    this._mainToIsolate.send(request);
  }

  static void _workerMain(dynamic message) {
    SendPort isolateToMain;
    final mainToIsolate = ReceivePort();
    final handlerRegistry = IsolateHandlerRegistry();

    if (message is InitMsg) {
      isolateToMain = message.sendPort;
      setupIsolatedServiceLocator(message, isolateToMain, handlerRegistry);
      getIt.allReady().then((value) {
        isolateToMain.send(mainToIsolate.sendPort);
      });
    }

    mainToIsolate.listen((message) {
      handlerRegistry.handleMessage(message);
    });
  }
}
