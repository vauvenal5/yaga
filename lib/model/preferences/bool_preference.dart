import 'package:yaga/model/preferences/section_preference.dart';
import 'package:yaga/model/preferences/value_preference.dart';

class BoolPreference extends ValuePreference<bool> {
  BoolPreference(key, title, value) : super(key, title, value);
  BoolPreference.section(SectionPreference section, key, title, bool value)
      : super.section(section, key, title, value);
}
