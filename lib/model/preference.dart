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

class StringPreference extends Preference {
  String value;

  StringPreference(key, title, this.value) : super(key, title);
  StringPreference.section(SectionPreference section, key, title, this.value) : super.prefixed(section.key, key, title);
}

