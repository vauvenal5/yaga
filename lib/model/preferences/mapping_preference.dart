//todo: Preference clone functions should be unified
library preference;

import 'package:built_value/built_value.dart';
import 'package:yaga/model/preferences/complex_preference.dart';
import 'package:yaga/model/preferences/serializers/base_type_serializer.dart';
import 'package:yaga/model/preferences/uri_preference.dart';

part 'mapping_preference.g.dart';

abstract class MappingPreference
    with BaseTypeSerializer<bool, ComplexPreference>
    implements
        ComplexPreference,
        Built<MappingPreference, MappingPreferenceBuilder> {
  UriPreference get remote;
  UriPreference get local;

  //todo: still need a solution for key prefixes
  static void _initializeBuilder(MappingPreferenceBuilder b) =>
      ComplexPreference.initBuilder<MappingPreferenceBuilder>(b)
        ..value = true
        ..remote.key = "remote"
        ..remote.title = "Remote Path"
        ..remote.fixedOrigin = true
        ..local.key = "local"
        ..local.title = "Local Path"
        ..local.fixedOrigin = true;

  factory MappingPreference([void Function(MappingPreferenceBuilder) updates]) =
      _$MappingPreference;
  MappingPreference._();
}
