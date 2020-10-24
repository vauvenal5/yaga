import 'package:yaga/model/preferences/section_preference.dart';
import 'package:yaga/model/preferences/value_preference.dart';

class StringListPreference extends ValuePreference<List<String>> {
  StringListPreference(String key, String title, List<String> value)
      : super(key, title, value);
  StringListPreference.section(
      SectionPreference section, key, title, List<String> value)
      : super.section(section, key, title, value);
}
