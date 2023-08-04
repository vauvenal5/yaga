import 'dart:async';
import 'dart:isolate';

import 'package:yaga/managers/isolateable/isolated_settings_manager.dart';
import 'package:yaga/services/isolateable/nextcloud_service.dart';
import 'package:yaga/utils/forground_worker/isolate_handler_regestry.dart';
import 'package:yaga/utils/forground_worker/isolate_msg_handler.dart';
import 'package:yaga/utils/forground_worker/messages/init_msg.dart';
import 'package:yaga/utils/forground_worker/messages/login_state_msg.dart';
import 'package:yaga/utils/forground_worker/messages/preference_msg.dart';
import 'package:yaga/utils/self_signed_cert_handler.dart';
import 'package:yaga/utils/service_locator.dart';

class UserHandler implements IsolateMsgHandler<UserHandler> {
  @override
  Future<UserHandler> initIsolated(InitMsg init, SendPort isolateToMain,
      IsolateHandlerRegistry registry) async {
    registry
        .registerHandler<LoginStateMsg>((msg) => handleLoginStateChanged(msg));
    registry.registerHandler<PreferenceMsg>(
      (msg) => getIt
          .get<IsolatedSettingsManager>()
          .updateSettingCommand(msg.preference),
    );
    return this;
  }

  void handleLoginStateChanged(LoginStateMsg message) {
    final NextCloudService ncService = getIt.get<NextCloudService>();

    if (message.loginData.server == null) {
      getIt.get<SelfSignedCertHandler>().revokeCert();
      return ncService.logout();
    }

    ncService.login(message.loginData);
    return;
  }
}
