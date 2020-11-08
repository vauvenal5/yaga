import 'dart:async';
import 'dart:isolate';

import 'package:path_provider/path_provider.dart';
import 'package:rx_command/rx_command.dart';
import 'package:yaga/managers/global_settings_manager.dart';
import 'package:yaga/managers/isolateable/isolated_settings_manager.dart';
import 'package:yaga/managers/isolateable/mapping_manager.dart';
import 'package:yaga/managers/nextcloud_manager.dart';
import 'package:yaga/services/isolateable/nextcloud_service.dart';
import 'package:yaga/utils/forground_worker/handlers/file_list_request_handler.dart';
import 'package:yaga/utils/forground_worker/messages/file_list_request.dart';
import 'package:yaga/utils/forground_worker/messages/init_msg.dart';
import 'package:yaga/utils/forground_worker/messages/login_state_msg.dart';
import 'package:yaga/utils/forground_worker/messages/preference_msg.dart';
import 'package:yaga/utils/forground_worker/messages/message.dart';
import 'package:yaga/utils/service_locator.dart';

class ForegroundWorker {
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

    if (message is InitMsg) {
      isolateToMain = message.sendPort;
      setupIsolatedServiceLocator(message);
      getIt.allReady().then((value) {
        getIt.get<MappingManager>().handleMappingUpdate(message.mapping);
        isolateToMain.send(mainToIsolate.sendPort);
      });
    }

    mainToIsolate.listen((message) {
      if (message is FileListRequest) {
        FileListRequestHandler.handle(message, isolateToMain);
        return;
      }

      if (message is PreferenceMsg) {
        getIt
            .get<IsolatedSettingsManager>()
            .updateSettingCommand(message.preference);
        return;
      }

      if (message is LoginStateMsg) {
        NextCloudService ncService = getIt.get<NextCloudService>();

        if (message.loginData.server == null) {
          return ncService.logout();
        }

        ncService.login(message.loginData);
        return;
      }
    });
  }
}
