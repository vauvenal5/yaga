library preference;

import 'package:built_value/built_value.dart';
import 'package:yaga/model/preferences/serializable_preference.dart';
import 'package:yaga/model/preferences/serializers/base_type_serializer.dart';
import 'package:yaga/model/preferences/value_preference.dart';

part 'bool_preference.g.dart';

abstract class BoolPreference
    with BaseTypeSerializer<bool, BoolPreference>
    implements
        SerializablePreference<bool, bool, BoolPreference>,
        Built<BoolPreference, BoolPreferenceBuilder> {
  static void _initializeBuilder(BoolPreferenceBuilder b) =>
      ValuePreference.initBuilder(b);

  factory BoolPreference([void Function(BoolPreferenceBuilder) updates]) =
      _$BoolPreference;
  BoolPreference._();
}
