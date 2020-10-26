library preference;

import 'package:built_value/built_value.dart';
import 'package:yaga/model/preferences/serializable_preference.dart';
import 'package:yaga/model/preferences/serializers/base_type_serializer.dart';
import 'package:yaga/model/preferences/value_preference.dart';

part 'string_preference.g.dart';

abstract class StringPreference
    with BaseTypeSerializer<String, StringPreference>
    implements
        SerializablePreference<String, String, StringPreference>,
        Built<StringPreference, StringPreferenceBuilder> {
  static void _initializeBuilder(StringPreferenceBuilder b) =>
      ValuePreference.initBuilder(b);

  factory StringPreference([void Function(StringPreferenceBuilder) updates]) =
      _$StringPreference;
  StringPreference._();
}
