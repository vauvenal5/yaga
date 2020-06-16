import 'package:flutter/material.dart';
import 'package:yaga/managers/settings_manager.dart';
import 'package:yaga/model/preference.dart';
import 'package:yaga/model/route_args/path_selector_screen_arguments.dart';
import 'package:yaga/utils/service_locator.dart';
import 'package:yaga/views/screens/path_selector_screen.dart';
import 'package:yaga/views/widgets/preferences/section_preference_widget.dart';
import 'package:yaga/views/widgets/preferences/string_preference_widget.dart';

class SettingsScreen extends StatelessWidget {
  static const String route = "/settings";

  final List<Preference> _defaultPreferences;

  SettingsScreen(this._defaultPreferences);

  Uri _buildSubUri(Uri uri, String segment) {
    String path = "";
    int index = uri.pathSegments.indexOf(segment);
    for(int i =0;i<=index;i++) {
      path += "/${uri.pathSegments[i]}";
    }
    return Uri(scheme: uri.scheme, userInfo: uri.userInfo, host: uri.host, path: path);
  }

  void _pushToNavigation(BuildContext context, StringPreference pref, Uri uri) {
    Navigator.pushNamed(
      context, 
      PathSelectorScreen.route, 
      arguments: PathSelectorScreenArguments(
        uri: uri,
        onCancel: () => Navigator.popUntil(context, ModalRoute.withName(SettingsScreen.route)), 
        onSelect: (Uri path) {
          Navigator.popUntil(context, ModalRoute.withName(SettingsScreen.route));
          getIt.get<SettingsManager>().updateSettingCommand(StringPreference(pref.key, pref.title, path.toString()));
        }
      )
    );
  }

  //todo: track issue https://github.com/flutter/flutter/issues/45938 and improve this madness when possible
  void _pushViews(BuildContext context, StringPreference pref) {
    Uri uri = Uri.parse(pref.value);
    _pushToNavigation(context, pref, Uri(scheme: uri.scheme, userInfo: uri.userInfo, host: uri.host, path: "/"));
    for(String segment in uri.pathSegments) {
      _pushToNavigation(context, pref, _buildSubUri(uri, segment));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Settings"),
      ),
      body: ListView.separated(
        itemBuilder: (context, index) {
          Preference defaultPref = _defaultPreferences[index];

          if(defaultPref is StringPreference) {
            return StringPreferenceWidget(
              defaultPref, 
              (pref) => _pushViews(context, pref)
            );
          }
          
          return SectionPreferenceWidget(defaultPref);
          
        }, 
        separatorBuilder: (context, index) => const Divider(), 
        itemCount: _defaultPreferences.length
      )
    );
  }
}