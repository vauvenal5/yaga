import 'package:yaga/model/preferences/section_preference.dart';
import 'package:yaga/model/preferences/string_preference.dart';

class ChoicePreference extends StringPreference {
  final Map<String, String> choices;

  ChoicePreference(key, title, value, this.choices) : super(key, title, value);
  ChoicePreference.section(
      SectionPreference section, key, title, value, this.choices)
      : super.section(section, key, title, value);
}
