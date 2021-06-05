//todo: Preference clone functions should be unified
library preference;

import 'package:built_value/built_value.dart';
import 'package:yaga/model/preferences/bool_preference.dart';
import 'package:yaga/model/preferences/complex_preference.dart';
import 'package:yaga/model/preferences/preference.dart';
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
  BoolPreference get syncDeletes;

  //todo: still need a solution for key prefixes
  static void _initializeBuilder(MappingPreferenceBuilder b) =>
      ComplexPreference.initBuilder<MappingPreferenceBuilder>(b)
        ..value = true
        ..remote.key = "remote"
        ..remote.title = "Remote Path"
        //todo: scheme has to be retrieved from actual service
        ..remote.schemeFilter = "nc"
        ..local.key = "local"
        ..local.title = "Local Path"
        ..local.schemeFilter = "file"
        ..syncDeletes.key = "syncDeletes"
        ..syncDeletes.title = "Sync Server Deletes"
        ..syncDeletes.value = true;

  static void _finalizeBuilder(MappingPreferenceBuilder b) => b
    ..remote.key = Preference.prefixKey(b.key, b.remote.key)
    ..local.key = Preference.prefixKey(b.key, b.local.key)
    ..syncDeletes.key = Preference.prefixKey(b.key, b.syncDeletes.key);

  factory MappingPreference([void Function(MappingPreferenceBuilder) updates]) =
      _$MappingPreference;
  MappingPreference._();
}
