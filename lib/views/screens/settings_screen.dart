import 'package:flutter/material.dart';
import 'package:yaga/managers/settings_manager.dart';
import 'package:yaga/model/preference.dart';
import 'package:yaga/utils/service_locator.dart';
import 'package:yaga/utils/path_selector_screen_arguments.dart';
import 'package:yaga/utils/uri_utils.dart';
import 'package:yaga/views/screens/path_selector_screen.dart';
import 'package:yaga/views/widgets/preferences/section_preference_widget.dart';
import 'package:yaga/views/widgets/preferences/string_preference_widget.dart';

class SettingsScreen extends StatelessWidget {
  static const String route = "/settings";

  final List<Preference> _defaultPreferences;

  SettingsScreen(this._defaultPreferences);

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
              (pref) => Navigator.pushNamed(
                context, 
                PathSelectorScreen.route, 
                arguments: PathSelectorScreenArguments(
                  uri: Uri.parse(pref.value),//UriUtils.createLocalUri(pref.value),
                  onCancel: () => Navigator.popUntil(context, ModalRoute.withName(SettingsScreen.route)), 
                  onSelect: (Uri path) {
                    Navigator.popUntil(context, ModalRoute.withName(SettingsScreen.route));
                    getIt.get<SettingsManager>().updateSettingCommand(StringPreference(pref.key, pref.title, path.toString()));
                  }
                )
              )
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