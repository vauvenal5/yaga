import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:yaga/utils/logger.dart';

abstract class Service<T extends Service<T>> {
  @protected
  Logger logger = YagaLogger.getLogger(T);

  Future<T> init() async => this;
}
