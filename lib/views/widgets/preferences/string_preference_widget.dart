import 'package:flutter/material.dart';
import 'package:yaga/model/preferences/string_preference.dart';
import 'package:yaga/services/shared_preferences_service.dart';
import 'package:yaga/utils/service_locator.dart';
import 'package:yaga/views/widgets/preferences/preference_list_tile_widget.dart';

class StringPreferenceWidget extends StatelessWidget {
  final StringPreference _defaultPreference;
  final Function(StringPreference) _onTap;

  StringPreferenceWidget(this._defaultPreference, this._onTap);

  @override
  Widget build(BuildContext context) {
    return PreferenceListTileWidget<StringPreference>(
        initData: getIt
            .get<SharedPreferencesService>()
            .loadStringPreference(_defaultPreference),
        listTileBuilder: (context, pref) => ListTile(
              title: Text(pref.title),
              subtitle: Text(pref.value),
              onTap: () => _onTap(pref),
            ));
  }
}
