import 'dart:isolate';

import 'package:yaga/utils/forground_worker/messages/init_msg.dart';

abstract class Isolateable<T extends Isolateable<T>> {
  Future<T> initIsolated(InitMsg init, SendPort isolateToMain) async => this as T;
}
