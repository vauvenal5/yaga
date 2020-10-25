library preference;

import 'package:built_value/built_value.dart';
import 'package:yaga/model/preferences/value_preference.dart';

part 'string_preference.g.dart';

abstract class StringPreference
    implements
        ValuePreference<String>,
        Built<StringPreference, StringPreferenceBuilder> {
  static void _initializeBuilder(StringPreferenceBuilder b) =>
      ValuePreference.initBuilder(b);

  factory StringPreference([void Function(StringPreferenceBuilder) updates]) =
      _$StringPreference;
  StringPreference._();
}
