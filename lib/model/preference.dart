abstract class Preference {
  String key;
  String title;

  Preference(this.key, this.title, {String prefix}) {
    if(prefix != null) {
      this.key = prefix + ":" + this.key;
    }
  }
}

class SectionPreference extends Preference {
  SectionPreference(key, title) : super(key, title);
  SectionPreference.route(route, key, title) : super(key, title, prefix: route);
}

abstract class ValuePreference<T> extends Preference {
  T value;

  ValuePreference(String key, String title, this.value, {String prefix}) : super(key, title, prefix: prefix);
  ValuePreference.section(SectionPreference section, key, title, this.value) : super(key, title, prefix: section.key);
}

class StringPreference extends ValuePreference<String> {
  StringPreference(key, title, value) : super(key, title, value);
  StringPreference.section(SectionPreference section, String key, String title, String value) : super.section(section, key, title, value);
}

class UriPreference extends ValuePreference<Uri> {
  UriPreference(String key, String title, Uri value, {String prefix}) : super(key, title, value, prefix: prefix);
  UriPreference.section(SectionPreference section, String key, String title, Uri value) : super.section(section, key, title, value);
}

class StringListPreference extends ValuePreference<List<String>> {
  StringListPreference(String key, String title, List<String> value) : super(key, title, value);
  StringListPreference.section(SectionPreference section, key, title, List<String> value) : super.section(section, key, title, value);
}

abstract class ComplexPreference extends ValuePreference<bool> {
  ComplexPreference(String key, String title, bool active) : super(key, title, active);
  ComplexPreference.section(SectionPreference section, key, title, bool active) : super.section(section, key, title, active);
}

class MappingPreference extends ComplexPreference {
  UriPreference remote;
  UriPreference local;

  MappingPreference(String key, String title, this.remote, this.local, {bool active = false}) : super(key, title, active);
  MappingPreference.section(SectionPreference section, key, title, {Uri remote, Uri local, bool active = false}) 
    : super.section(section, key, title, active) {
    this.remote = UriPreference("remote", "Remote Path", remote??Uri(), prefix: this.key);
    this.local = UriPreference("local", "Local Path", local??Uri(), prefix: this.key);
  }
}