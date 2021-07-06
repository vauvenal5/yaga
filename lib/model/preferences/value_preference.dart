library preference;

import 'package:built_value/built_value.dart';
import 'package:flutter/foundation.dart';
import 'package:yaga/model/preferences/preference.dart';

part 'value_preference.g.dart';

@BuiltValue(instantiable: false)
abstract class ValuePreference<T> implements Preference {
  T get value;

  @protected
  static T initBuilder<T extends ValuePreferenceBuilder>(
          ValuePreferenceBuilder b) =>
      Preference.initBuilder(b);

  @override
  ValuePreference<T> rebuild(void Function(ValuePreferenceBuilder<T>) updates);
  @override
  ValuePreferenceBuilder<T> toBuilder();
}
