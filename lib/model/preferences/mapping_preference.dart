//todo: Preference clone functions should be unified
import 'package:yaga/model/preferences/complex_preference.dart';
import 'package:yaga/model/preferences/section_preference.dart';
import 'package:yaga/model/preferences/uri_preference.dart';

class MappingPreference extends ComplexPreference {
  final UriPreference remote;
  final UriPreference local;

  MappingPreference(String key, String title, Uri remote, Uri local,
      {bool active = false})
      : this.remote = _getRemoteUri(key, remote),
        this.local = _getLocalUri(key, local),
        super(key, title, active);
  MappingPreference.section(SectionPreference section, key, title,
      {Uri remote, Uri local, bool active = false})
      : this.remote = _getRemoteUri(key, remote),
        this.local = _getLocalUri(key, local),
        super.section(section, key, title, active);
  MappingPreference.fromSelf(MappingPreference pref, this.local, this.remote)
      : super(pref.key, pref.title, pref.value);

  static UriPreference _getRemoteUri(String key, Uri remote) =>
      UriPreference("remote", "Remote Path", remote ?? Uri(),
          prefix: key, fixedOrigin: true);

  static UriPreference _getLocalUri(String key, Uri local) =>
      UriPreference("local", "Local Path", local ?? Uri(),
          prefix: key, fixedOrigin: true);
}
