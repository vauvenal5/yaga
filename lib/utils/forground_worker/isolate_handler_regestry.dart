import 'package:yaga/utils/forground_worker/messages/message.dart';
import 'package:yaga/utils/logger.dart';

class IsolateHandlerRegistry {
  final logger = YagaLogger.getLogger(IsolateHandlerRegistry);
  final Map<Type, List<Function(Message)>> handlers = {};

  void registerHandler<M extends Message>(Function(M) handler) {
    handlers.putIfAbsent(M, () => []);
    handlers[M].add((Message msg) => handler(msg as M));
  }

  void handleMessage(Message msg) {
    if (handlers.containsKey(msg.runtimeType)) {
      for (final handler in handlers[msg.runtimeType]) {
        handler(msg);
      }
    } else {
      logger.shout("No handler registered for ${msg.runtimeType}");
    }
  }
}
