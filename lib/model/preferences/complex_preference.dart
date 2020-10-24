import 'package:yaga/model/preferences/section_preference.dart';
import 'package:yaga/model/preferences/value_preference.dart';

abstract class ComplexPreference extends ValuePreference<bool> {
  ComplexPreference(String key, String title, bool active)
      : super(key, title, active);
  ComplexPreference.section(SectionPreference section, key, title, bool active)
      : super.section(section, key, title, active);
}
