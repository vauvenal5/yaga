import 'package:flutter/material.dart';
import 'package:rx_command/rx_command.dart';
import 'package:yaga/managers/settings_manager.dart';
import 'package:yaga/model/preference.dart';
import 'package:yaga/model/route_args/choice_selector_screen_arguments.dart';
import 'package:yaga/services/shared_preferences_service.dart';
import 'package:yaga/utils/service_locator.dart';
import 'package:yaga/views/screens/choice_selector_screen.dart';
import 'package:yaga/views/widgets/preferences/preference_list_tile_widget.dart';

class ChoicePreferenceWidget extends StatelessWidget {
  final ChoicePreference _choicePreference;
  final RxCommand<Preference, dynamic> onChangeCommand;

  ChoicePreferenceWidget(this._choicePreference, this.onChangeCommand);

  //todo: generalize this for all preferences
  void _notifyChange(ChoicePreference pref) {
    if(onChangeCommand != null) {
      onChangeCommand(pref);
      return;
    }
    getIt.get<SettingsManager>().persistChoiceSettingCommand(pref);
  }
  
  @override
  Widget build(BuildContext context) {
    return PreferenceListTileWidget<ChoicePreference>(
      initData: getIt.get<SharedPreferencesService>().loadChoicePreference(_choicePreference), 
      listTileBuilder: (context, pref) => ListTile(
        title: Text(pref.title),
        subtitle: Text(pref.choices[pref.value]),
        onTap: () => Navigator.pushNamed(
          context, 
          ChoiceSelectorScreen.route,
          arguments: ChoiceSelectorScreenArguments(
            pref, 
            (String value) {
              Navigator.pop(context);
              this._notifyChange(ChoicePreference(pref.key, pref.title, value, pref.choices));
            },
            () => Navigator.pop(context)
          )
        ),
      )
    );
  }

}