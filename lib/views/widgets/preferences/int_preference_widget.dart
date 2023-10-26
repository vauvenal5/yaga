import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rx_command/rx_command.dart';
import 'package:yaga/managers/settings_manager.dart';
import 'package:yaga/model/preferences/int_preference.dart';
import 'package:yaga/model/preferences/preference.dart';
import 'package:yaga/services/shared_preferences_service.dart';
import 'package:yaga/utils/service_locator.dart';
import 'package:yaga/views/widgets/preferences/preference_list_tile_widget.dart';

class IntPreferenceWidget extends StatefulWidget {
  final IntPreference _defaultPreference;
  final RxCommand<Preference, dynamic>? _onChangeCommand;

  const IntPreferenceWidget(this._defaultPreference, this._onChangeCommand);

  @override
  State<IntPreferenceWidget> createState() => _IntPreferenceWidgetState();
}

class _IntPreferenceWidgetState extends State<IntPreferenceWidget> {
  GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  //todo: generalize this for all preferences
  void _notifyChange(IntPreference pref) {
    if (widget._onChangeCommand != null) {
      widget._onChangeCommand!(pref);
      return;
    }
    getIt.get<SettingsManager>().persistIntSettingCommand(pref);
  }

  bool _validate(String interval) {
    return (int.tryParse(interval) ?? 0) > 0;
  }

  @override
  Widget build(BuildContext context) {
    return PreferenceListTileWidget<IntPreference>(
      initData: getIt
          .get<SharedPreferencesService>()
          .loadPreferenceFromInt(widget._defaultPreference),
      listTileBuilder: (context, pref) => ListTile(
        title: Text(pref.title!),
        subtitle: Text(pref.value.toString()),
        onTap: () => showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(pref.title!),
            content: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: TextFormField(
                keyboardType: TextInputType.number,
                initialValue: pref.value.toString(),
                onSaved: (newValue) => _notifyChange(
                  pref.rebuild(
                        (b) => b..value = int.parse(newValue!),
                  ),
                ),
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.digitsOnly
                ],
                validator: (v) => _validate(v ?? "")
                    ? null
                    : "Number has to be bigger than 0.",
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  if(_formKey.currentState?.validate()??false) {
                    _formKey.currentState?.save();
                    Navigator.pop(context);
                  }
                },
                child: Text("Ok"),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text("Cancel"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
