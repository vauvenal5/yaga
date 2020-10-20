abstract class Preference {
  String key;
  String title;
  bool enabled;

  Preference(this.key, this.title, {String prefix, this.enabled = true}) {
    if (prefix != null) {
      this.key = prefix + ":" + this.key;
    }
  }
}

//todo: refactor all preferences to respect enabled
class SectionPreference extends Preference {
  SectionPreference(key, title) : super(key, title);
  SectionPreference.route(route, key, title) : super(key, title, prefix: route);
}

abstract class ValuePreference<T> extends Preference {
  T value;

  ValuePreference(String key, String title, this.value,
      {String prefix, bool enabled = true})
      : super(key, title, prefix: prefix, enabled: enabled);
  ValuePreference.section(SectionPreference section, key, title, this.value,
      {bool enabled = true})
      : super(key, title, prefix: section.key, enabled: enabled);
}

class StringPreference extends ValuePreference<String> {
  StringPreference(key, title, value) : super(key, title, value);
  StringPreference.section(
      SectionPreference section, String key, String title, String value)
      : super.section(section, key, title, value);
}

class UriPreference extends ValuePreference<Uri> {
  UriPreference(String key, String title, Uri value,
      {String prefix, bool enabled = true})
      : super(key, title, value, prefix: prefix, enabled: enabled);
  UriPreference.section(
      SectionPreference section, String key, String title, Uri value,
      {bool enabled = true})
      : super.section(section, key, title, value, enabled: enabled);
}

class StringListPreference extends ValuePreference<List<String>> {
  StringListPreference(String key, String title, List<String> value)
      : super(key, title, value);
  StringListPreference.section(
      SectionPreference section, key, title, List<String> value)
      : super.section(section, key, title, value);
}

abstract class ComplexPreference extends ValuePreference<bool> {
  ComplexPreference(String key, String title, bool active)
      : super(key, title, active);
  ComplexPreference.section(SectionPreference section, key, title, bool active)
      : super.section(section, key, title, active);
}

class MappingPreference extends ComplexPreference {
  UriPreference remote;
  UriPreference local;

  MappingPreference(String key, String title, this.remote, this.local,
      {bool active = false})
      : super(key, title, active);
  MappingPreference.section(SectionPreference section, key, title,
      {Uri remote, Uri local, bool active = false})
      : super.section(section, key, title, active) {
    this.remote = UriPreference("remote", "Remote Path", remote ?? Uri(),
        prefix: this.key);
    this.local =
        UriPreference("local", "Local Path", local ?? Uri(), prefix: this.key);
  }
}

class BoolPreference extends ValuePreference<bool> {
  BoolPreference(key, title, value) : super(key, title, value);
  BoolPreference.section(SectionPreference section, key, title, bool value)
      : super.section(section, key, title, value);
}

class ChoicePreference extends StringPreference {
  final Map<String, String> choices;

  ChoicePreference(key, title, value, this.choices) : super(key, title, value);
  ChoicePreference.section(
      SectionPreference section, key, title, value, this.choices)
      : super.section(section, key, title, value);
}
