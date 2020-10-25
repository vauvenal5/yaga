library preference;

import 'package:built_value/built_value.dart';
import 'package:flutter/foundation.dart';
import 'package:yaga/model/preferences/value_preference.dart';

part 'complex_preference.g.dart';

@BuiltValue(instantiable: false)
abstract class ComplexPreference implements ValuePreference<bool> {
  @protected
  static T initBuilder<T extends ComplexPreferenceBuilder>(T b) =>
      ValuePreference.initBuilder(b);

  ComplexPreference rebuild(void Function(ComplexPreferenceBuilder) updates);
  ComplexPreferenceBuilder toBuilder();
}
