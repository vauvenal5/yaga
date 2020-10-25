import 'package:yaga/model/preferences/serializers/preference_serializer.dart';
import 'package:yaga/model/preferences/uri_preference.dart';

mixin UriSerializer
    implements PreferenceSerializer<String, Uri, UriPreference> {
  @override
  String serialize() {
    return this.value.toString();
  }

  @override
  UriPreference deserialize(String value) {
    return value == null
        ? this
        : this.rebuild((b) => b..value = Uri.parse(value));
  }
}
