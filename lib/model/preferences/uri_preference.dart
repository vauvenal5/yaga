library preference;

import 'package:built_value/built_value.dart';
import 'package:yaga/model/preferences/value_preference.dart';

part 'uri_preference.g.dart';

abstract class UriPreference
    implements
        ValuePreference<Uri>,
        Built<UriPreference, UriPreferenceBuilder> {
  bool get fixedOrigin;

  static void _initializeBuilder(UriPreferenceBuilder b) =>
      ValuePreference.initBuilder<UriPreferenceBuilder>(b)..fixedOrigin = false;

  factory UriPreference([void Function(UriPreferenceBuilder) updates]) =
      _$UriPreference;
  UriPreference._();
}
