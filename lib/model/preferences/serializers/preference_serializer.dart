import 'package:yaga/model/preferences/value_preference.dart';

mixin PreferenceSerializer<SerializableType, ValueType,
        PreferenzeType extends ValuePreference<ValueType>>
    implements ValuePreference<ValueType> {
  SerializableType serialize();
  PreferenzeType deserialize(SerializableType value);
}
