import 'package:flutter/material.dart';
import 'package:yaga/managers/settings_manager.dart';
import 'package:yaga/model/preference.dart';
import 'package:yaga/model/route_args/settings_screen_arguments.dart';
import 'package:yaga/utils/service_locator.dart';
import 'package:yaga/views/screens/settings_screen.dart';
import 'package:yaga/views/widgets/preferences/preference_list_tile_widget.dart';

class MappingPreferenceWidget extends StatefulWidget {
  final MappingPreference pref;
  final String route;

  MappingPreferenceWidget(this.pref, this.route);

  @override
  State<StatefulWidget> createState() => _MappingPreferenceState();
}

class _MappingPreferenceState extends State<MappingPreferenceWidget> {
  _MappingPreferenceState() {
    getIt
        .get<SettingsManager>()
        .updateSettingCommand
        .where((event) =>
            event.key == widget.pref.remote.key ||
            event.key == widget.pref.local.key)
        .map((event) => event as UriPreference)
        .listen((pref) {
      if (pref.key.endsWith("remote")) {
        widget.pref.remote = pref;
      } else {
        widget.pref.local = pref;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return PreferenceListTileWidget<MappingPreference>(
      initData: widget.pref,
      listTileBuilder: (context, pref) => ListTile(
        title: Text(pref.title),
        onTap: () => Navigator.pushNamed(
          context,
          SettingsScreen.route,
          arguments: SettingsScreenArguments(
            onSettingChangedCommand:
                getIt.get<SettingsManager>().updateSettingCommand,
            preferences: [pref.remote, pref.local],
            onCancel: () => Navigator.pop(context),
            onCommit: () {
              Navigator.pop(context);
              getIt
                  .get<SettingsManager>()
                  .persistMappingPreferenceCommand(widget.pref);
            },
          ),
        ),
      ),
    );
  }
}
