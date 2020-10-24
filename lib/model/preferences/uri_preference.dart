import 'package:yaga/model/preferences/section_preference.dart';
import 'package:yaga/model/preferences/value_preference.dart';

class UriPreference extends ValuePreference<Uri> {
  final bool fixedOrigin;

  UriPreference(String key, String title, Uri value,
      {String prefix, bool enabled = true, this.fixedOrigin = false})
      : super(key, title, value, prefix: prefix, enabled: enabled);
  UriPreference.section(
      SectionPreference section, String key, String title, Uri value,
      {bool enabled = true, this.fixedOrigin = false})
      : super.section(section, key, title, value, enabled: enabled);
}
