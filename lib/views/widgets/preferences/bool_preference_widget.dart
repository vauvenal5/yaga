import 'package:flutter/material.dart';
import 'package:rx_command/rx_command.dart';
import 'package:yaga/managers/settings_manager.dart';
import 'package:yaga/model/preferences/bool_preference.dart';
import 'package:yaga/model/preferences/preference.dart';
import 'package:yaga/services/shared_preferences_service.dart';
import 'package:yaga/utils/service_locator.dart';
import 'package:yaga/views/widgets/preferences/preference_list_tile_widget.dart';

class BoolPreferenceWidget extends StatelessWidget {
  final BoolPreference _defaultPreference;
  final RxCommand<Preference, dynamic>? onChangeCommand;

  const BoolPreferenceWidget(this._defaultPreference, {this.onChangeCommand});

  //todo: generalize this for all preferences
  void _notifyChange(BoolPreference pref) {
    if (onChangeCommand != null) {
      onChangeCommand!(pref);
      return;
    }
    getIt.get<SettingsManager>().persistBoolSettingCommand(pref);
  }

  @override
  Widget build(BuildContext context) {
    return PreferenceListTileWidget<BoolPreference>(
      initData: getIt
          .get<SharedPreferencesService>()
          .loadPreferenceFromBool(_defaultPreference),
      listTileBuilder: (context, pref) => SwitchListTile(
        title: Text(pref.title!),
        value: pref.value,
        onChanged: pref.enabled! ?
            (value) => _notifyChange(pref.rebuild((b) => b..value = value)) :
            null,
      ),
    );
  }
}
