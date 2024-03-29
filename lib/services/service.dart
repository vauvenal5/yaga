import 'package:flutter/foundation.dart';
import 'package:yaga/utils/logger.dart';

mixin class Service<T extends Service<T>> {
  @protected
  final logger = YagaLogger.getLogger(T);

  Future<T> init() async => this as T;
}
