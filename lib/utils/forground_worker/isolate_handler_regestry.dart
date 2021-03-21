import 'package:yaga/utils/forground_worker/messages/message.dart';
import 'package:yaga/utils/logger.dart';

class IsolateHandlerRegistry {
  final logger = YagaLogger.getLogger(IsolateHandlerRegistry);
  final Map<Type, List<Function(Message)>> handlers = Map();

  void registerHandler<M extends Message>(Function(M) handler) {
    this.handlers.putIfAbsent(M, () => List());
    this.handlers[M].add((Message msg) => handler(msg as M));
  }

  void handleMessage(Message msg) {
    if (this.handlers.containsKey(msg.runtimeType)) {
      this.handlers[msg.runtimeType].forEach((handler) => handler(msg));
    } else {
      logger.shout("No handler registered for ${msg.runtimeType}");
    }
  }
}
