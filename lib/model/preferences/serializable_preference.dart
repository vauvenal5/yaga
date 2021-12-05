library preference;

import 'package:built_value/built_value.dart';
import 'package:flutter/foundation.dart';
import 'package:yaga/model/preferences/value_preference.dart';

part 'serializable_preference.g.dart';

@BuiltValue(instantiable: false)
abstract class SerializablePreference<SerializableType, ValueType,
        PreferenceType extends ValuePreference<ValueType>>
    implements ValuePreference<ValueType> {
  @protected
  static T initBuilder<T extends ValuePreferenceBuilder>(
          ValuePreferenceBuilder b) =>
      ValuePreference.initBuilder(b);

  SerializableType serialize();
  PreferenceType deserialize(SerializableType? value);

  @override
  PreferenceType rebuild(
      void Function(
              SerializablePreferenceBuilder<SerializableType, ValueType,
                  PreferenceType>)
          updates);
  @override
  SerializablePreferenceBuilder<SerializableType, ValueType, PreferenceType>
      toBuilder();
}
