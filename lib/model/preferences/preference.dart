library preference;

import 'package:built_value/built_value.dart';
import 'package:flutter/foundation.dart';

part 'preference.g.dart';

@BuiltValue(instantiable: false)
abstract class Preference {
  String get key;
  String get title;
  bool get enabled;

  static String prefixKey(String prefix, String key) =>
      key.startsWith(prefix) ? key : "$prefix:$key";

  @protected
  static PreferenceBuilder initBuilder<T extends PreferenceBuilder>(PreferenceBuilder b) =>
      b..enabled = true;

  Preference rebuild(void Function(PreferenceBuilder) updates);
  PreferenceBuilder toBuilder();
}
