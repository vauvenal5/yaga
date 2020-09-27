import 'dart:async';
import 'dart:isolate';

import 'package:path_provider/path_provider.dart';
import 'package:rx_command/rx_command.dart';
import 'package:yaga/managers/isolateable/isolated_file_manager.dart';
import 'package:yaga/managers/isolateable/isolated_settings_manager.dart';
import 'package:yaga/services/isolateable/nextcloud_service.dart';
import 'package:yaga/utils/forground_worker/messages/file_list_done.dart';
import 'package:yaga/utils/forground_worker/messages/file_list_request.dart';
import 'package:yaga/utils/forground_worker/messages/file_list_response.dart';
import 'package:yaga/utils/forground_worker/messages/init_msg.dart';
import 'package:yaga/utils/forground_worker/messages/login_state_msg.dart';
import 'package:yaga/utils/forground_worker/messages/preference_msg.dart';
import 'package:yaga/utils/forground_worker/messages/message.dart';
import 'package:yaga/utils/service_locator.dart';

class ForegroundWorker {
  Isolate _isolate;
  SendPort _mainToIsolate;
  final _isolateReady = Completer<ForegroundWorker>();

  RxCommand<Message, Message> isolateResponseCommand;

  Future<ForegroundWorker> init() async {
    isolateResponseCommand = RxCommand.createSync((param) => param);
    final isolateToMain = ReceivePort();

    isolateToMain.listen((message) {
      if(message is SendPort) {
        this._mainToIsolate = message;
        _isolateReady.complete(this);
        return;
      }

      if(message is Message) {
        isolateResponseCommand(message);
      }
    });

    this._isolate = await Isolate.spawn(_workerMain, InitMsg(
      isolateToMain.sendPort, 
      await getExternalStorageDirectory(), 
      await getTemporaryDirectory()
    ));

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

    if(message is InitMsg) {
      isolateToMain = message.sendPort;
      setupIsolatedServiceLocator(message);
      isolateToMain.send(mainToIsolate.sendPort);
    }

    mainToIsolate.listen((message) {
      if(message is FileListRequest) {
        getIt.get<IsolatedFileManager>().listFileLists(message.uri, recursive: message.recursive)
          .listen((event) => isolateToMain.send(FileListResponse(message.key, event)))
          .onDone(() => isolateToMain.send(FileListDone(message.key)));
        return;
      }

      if(message is PreferenceMsg) {
        getIt.get<IsolatedSettingsManager>().updateSettingCommand(message.preference);
        return;
      }

      if(message is LoginStateMsg) {
        NextCloudService ncService = getIt.get<NextCloudService>();
        
        if(message.loginData.server == null) {
          return ncService.logout();
        }
        
        return ncService.login(message.loginData);
      }
    });
  }
}