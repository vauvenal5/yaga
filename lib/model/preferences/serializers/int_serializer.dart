import 'package:yaga/model/preferences/int_preference.dart';
import 'package:yaga/model/preferences/serializable_preference.dart';

mixin IntSerializer
implements SerializablePreference<String, int, IntPreference> {
  @override
  String serialize() {
    return value.toString();
  }

  @override
  IntPreference deserialize(String? value) {
    return value == null
        ? this as IntPreference
        : rebuild((b) => b..value = int.parse(value));
  }
}
