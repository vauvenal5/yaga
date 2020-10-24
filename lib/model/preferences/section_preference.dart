//todo: refactor all preferences to respect enabled
import 'package:yaga/model/preferences/preference.dart';

class SectionPreference extends Preference {
  SectionPreference(key, title) : super(key, title);
  SectionPreference.route(route, key, title) : super(key, title, prefix: route);
}
