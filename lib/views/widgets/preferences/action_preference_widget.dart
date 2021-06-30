import 'package:flutter/material.dart';
import 'package:yaga/model/preferences/action_preference.dart';

class ActionPreferenceWidget extends StatelessWidget {
  final ActionPreference _pref;

  const ActionPreferenceWidget(this._pref);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(
        _pref.title,
      ),
      onTap: _pref.action,
    );
  }
}
