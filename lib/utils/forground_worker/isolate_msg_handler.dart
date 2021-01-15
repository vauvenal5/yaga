import 'dart:isolate';

import 'package:yaga/utils/forground_worker/isolate_handler_regestry.dart';
import 'package:yaga/utils/forground_worker/messages/init_msg.dart';

abstract class IsolateMsgHandler<T extends IsolateMsgHandler<T>> {
  Future<T> initIsolated(
    InitMsg init,
    SendPort isolateToMain,
    IsolateHandlerRegistry registry,
  );
}
