abstract class Preference {
  String key;
  String title;

  Preference(this.key, this.title);
  Preference.prefixed(prefix, key, this.title) {
    this.key = prefix + ":" + key;
  }
}

class SectionPreference extends Preference {
  SectionPreference(key, title) : super(key, title);
  SectionPreference.route(route, key, title) : super.prefixed(route, key, title);
}

class ValuePreference<T> extends Preference {
  T value;

  ValuePreference(String key, String title, this.value) : super(key, title);
  ValuePreference.section(SectionPreference section, key, title, this.value) : super.prefixed(section.key, key, title);
}

class StringPreference extends ValuePreference<String> {
  StringPreference(key, title, value) : super(key, title, value);
  StringPreference.section(SectionPreference section, String key, String title, String value) : super.section(section, key, title, value);
}

class StringListPreference extends ValuePreference<List<String>> {
  StringListPreference(String key, String title, List<String> value) : super(key, title, value);
  StringListPreference.section(SectionPreference section, key, title, List<String> value) : super.section(section, key, title, value);
}
