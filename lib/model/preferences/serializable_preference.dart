import 'package:yaga/model/preferences/value_preference.dart';

abstract class SerializablePreference<V extends ValuePreference, T> {
  T getSerializedValue();
  V cloneWithDeserialized(T value);
}
