import 'package:flutter/material.dart';
import 'package:rx_command/rx_command.dart';
import 'package:yaga/model/preferences/bool_preference.dart';
import 'package:yaga/model/preferences/choice_preference.dart';
import 'package:yaga/model/preferences/mapping_preference.dart';
import 'package:yaga/model/preferences/preference.dart';
import 'package:yaga/model/preferences/uri_preference.dart';
import 'package:yaga/views/widgets/ok_cancel_button_bar.dart';
import 'package:yaga/views/widgets/preferences/BoolPreferenceWidget.dart';
import 'package:yaga/views/widgets/preferences/choice_preference_widget.dart';
import 'package:yaga/views/widgets/preferences/mapping_preference_widget.dart';
import 'package:yaga/views/widgets/preferences/section_preference_widget.dart';
import 'package:yaga/views/widgets/preferences/uri_preference_widget.dart';

class SettingsScreen extends StatelessWidget {
  static const String route = "/settings";

  final List<Preference> _defaultPreferences;
  final RxCommand<Preference, dynamic> onPreferenceChangedCommand;
  final Function onCommit;
  final Function onCancel;

  SettingsScreen(this._defaultPreferences,
      {this.onPreferenceChangedCommand, this.onCancel, this.onCommit});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Settings"),
      ),
      body: ListView.separated(
        itemBuilder: (context, index) {
          Preference defaultPref = _defaultPreferences[index];

          if (defaultPref is UriPreference) {
            return UriPreferenceWidget(
              defaultPref,
              onChangeCommand: this.onPreferenceChangedCommand,
            );
          }

          if (defaultPref is MappingPreference) {
            return MappingPreferenceWidget(defaultPref, SettingsScreen.route);
          }

          if (defaultPref is BoolPreference) {
            return BoolPreferenceWidget(
              defaultPref,
              onChangeCommand: this.onPreferenceChangedCommand,
            );
          }

          if (defaultPref is ChoicePreference) {
            return ChoicePreferenceWidget(
              defaultPref,
              this.onPreferenceChangedCommand,
            );
          }

          return SectionPreferenceWidget(defaultPref);
        },
        separatorBuilder: (context, index) => const Divider(),
        itemCount: _defaultPreferences.length,
      ),
      bottomNavigationBar: onCommit == null
          ? null
          : OkCancelButtonBar(onCommit: this.onCommit, onCancel: this.onCancel),
    );
  }
}
