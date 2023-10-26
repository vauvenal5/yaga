library preference;

import 'package:built_value/built_value.dart';
import 'package:yaga/model/preferences/serializable_preference.dart';
import 'package:yaga/model/preferences/serializers/base_type_serializer.dart';
import 'package:yaga/model/preferences/serializers/int_serializer.dart';
import 'package:yaga/model/preferences/value_preference.dart';

part 'int_preference.g.dart';

abstract class IntPreference
    with BaseTypeSerializer<int, IntPreference>
    implements
        SerializablePreference<int, int, IntPreference>,
        Built<IntPreference, IntPreferenceBuilder> {
  static void _initializeBuilder(IntPreferenceBuilder b) =>
      ValuePreference.initBuilder(b);

  factory IntPreference([void Function(IntPreferenceBuilder) updates]) =
      _$IntPreference;
  IntPreference._();
}
