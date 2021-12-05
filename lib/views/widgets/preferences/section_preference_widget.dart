import 'package:flutter/material.dart';
import 'package:yaga/model/preferences/preference.dart';

class SectionPreferenceWidget extends StatelessWidget {
  final Preference _pref;

  const SectionPreferenceWidget(this._pref);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(
        _pref.title!,
        style: TextStyle(
            color: Theme.of(context).accentColor, fontWeight: FontWeight.bold),
      ),
    );
  }
}
