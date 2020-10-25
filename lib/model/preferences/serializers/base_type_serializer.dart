import 'package:yaga/model/preferences/serializers/preference_serializer.dart';
import 'package:yaga/model/preferences/value_preference.dart';

mixin BaseTypeSerializer<T, P extends ValuePreference<T>>
    implements PreferenceSerializer<T, T, P> {
  @override
  T serialize() {
    return this.value;
  }

  @override
  P deserialize(T value) {
    return value == null ? this : this.rebuild((b) => b..value = value);
  }
}
