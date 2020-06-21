import 'package:flutter/material.dart';
import 'package:yaga/managers/settings_manager.dart';
import 'package:yaga/model/preference.dart';
import 'package:yaga/services/shared_preferences_service.dart';
import 'package:yaga/utils/service_locator.dart';

class StringPreferenceWidget extends StatelessWidget {
  final StringPreference _defaultPreference;
  final Function(StringPreference) _onTap;

  StringPreferenceWidget(this._defaultPreference, this._onTap);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<StringPreference>(
      stream: getIt.get<SettingsManager>().newLoadSettingCommand.where((event) => event.key == _defaultPreference.key).map((event) => event as StringPreference),
      initialData: getIt.get<SharedPreferencesService>().loadStringPreference(_defaultPreference),
      builder: (BuildContext context, AsyncSnapshot<StringPreference> snapshot) {
        return ListTile(
          title: Text(snapshot.data.title),
          subtitle: Text(snapshot.data.value),
          onTap: () => _onTap(snapshot.data),
        );
      },
    );
  }
}