import 'package:yaga/model/preferences/preference.dart';
import 'package:yaga/model/preferences/section_preference.dart';

abstract class ValuePreference<T> extends Preference {
  T value;

  ValuePreference(String key, String title, this.value,
      {String prefix, bool enabled = true})
      : super(key, title, prefix: prefix, enabled: enabled);
  ValuePreference.section(SectionPreference section, key, title, this.value,
      {bool enabled = true})
      : super(key, title, prefix: section.key, enabled: enabled);
}
