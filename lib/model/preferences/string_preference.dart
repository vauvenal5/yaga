import 'package:yaga/model/preferences/section_preference.dart';
import 'package:yaga/model/preferences/serializable_preference.dart';
import 'package:yaga/model/preferences/value_preference.dart';

class StringPreference extends ValuePreference<String> {
  StringPreference(key, title, value) : super(key, title, value);
  StringPreference.section(
      SectionPreference section, String key, String title, String value)
      : super.section(section, key, title, value);
}
