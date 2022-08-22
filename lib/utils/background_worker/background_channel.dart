import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:yaga/utils/background_worker/background_commands.dart';
import 'package:yaga/utils/background_worker/json_convertable.dart';

class BackgroundChannel{
  final AndroidServiceInstance service;

  BackgroundChannel(this.service);

  void send(JsonConvertable msg) => service.invoke(BackgroundCommands.workerToMain, msg.toJson());
}
