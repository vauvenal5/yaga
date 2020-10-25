//todo: refactor all preferences to respect enabled
library preference;

import 'package:built_value/built_value.dart';
import 'package:yaga/model/preferences/preference.dart';

part 'section_preference.g.dart';

abstract class SectionPreference
    implements Preference, Built<SectionPreference, SectionPreferenceBuilder> {
  String prepareKey(String keyPart) => Preference.prefixKey(this.key, keyPart);

  static void _initializeBuilder(SectionPreferenceBuilder b) =>
      Preference.initBuilder(b);

  factory SectionPreference([void Function(SectionPreferenceBuilder) updates]) =
      _$SectionPreference;
  SectionPreference._();
}
