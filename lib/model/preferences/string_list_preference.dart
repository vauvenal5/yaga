library preference;

import 'package:built_value/built_value.dart';
import 'package:yaga/model/preferences/serializers/base_type_serializer.dart';
import 'package:yaga/model/preferences/value_preference.dart';

part 'string_list_preference.g.dart';

abstract class StringListPreference
    with BaseTypeSerializer<List<String>, StringListPreference>
    implements
        ValuePreference<List<String>>,
        Built<StringListPreference, StringListPreferenceBuilder> {
  static void _initializeBuilder(StringListPreferenceBuilder b) =>
      ValuePreference.initBuilder(b);

  factory StringListPreference(
          [void Function(StringListPreferenceBuilder) updates]) =
      _$StringListPreference;
  StringListPreference._();
}
