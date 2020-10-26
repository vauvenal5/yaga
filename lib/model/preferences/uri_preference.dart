library preference;

import 'package:built_value/built_value.dart';
import 'package:yaga/model/preferences/serializable_preference.dart';
import 'package:yaga/model/preferences/serializers/uri_serializer.dart';
import 'package:yaga/model/preferences/value_preference.dart';

part 'uri_preference.g.dart';

abstract class UriPreference
    with UriSerializer
    implements
        SerializablePreference<String, Uri, UriPreference>,
        Built<UriPreference, UriPreferenceBuilder> {
  bool get fixedOrigin;

  static void _initializeBuilder(UriPreferenceBuilder b) =>
      ValuePreference.initBuilder<UriPreferenceBuilder>(b)..fixedOrigin = false;

  factory UriPreference([void Function(UriPreferenceBuilder) updates]) =
      _$UriPreference;
  UriPreference._();
}
