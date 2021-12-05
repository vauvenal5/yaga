import 'package:yaga/model/preferences/serializable_preference.dart';
import 'package:yaga/model/preferences/uri_preference.dart';

mixin UriSerializer
    implements SerializablePreference<String, Uri, UriPreference> {
  @override
  String serialize() {
    return value.toString();
  }

  @override
  UriPreference deserialize(String? value) {
    return value == null
        ? this as UriPreference
        : rebuild((b) => b..value = Uri.parse(value));
  }
}
