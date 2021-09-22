library preference;

import 'package:built_value/built_value.dart';
import 'package:flutter/foundation.dart';
import 'package:yaga/model/preferences/serializable_preference.dart';
import 'package:yaga/model/preferences/value_preference.dart';

part 'complex_preference.g.dart';

//todo: is the bool value ever used?
@BuiltValue(instantiable: false)
abstract class ComplexPreference
    implements SerializablePreference<bool, bool, ComplexPreference> {
  @protected
  static T initBuilder<T extends ComplexPreferenceBuilder>(T b) =>
      ValuePreference.initBuilder(b);

  @override
  ComplexPreference rebuild(void Function(ComplexPreferenceBuilder) updates);
  @override
  ComplexPreferenceBuilder toBuilder();
}
