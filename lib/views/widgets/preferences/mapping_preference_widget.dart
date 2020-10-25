import 'package:flutter/material.dart';
import 'package:yaga/managers/settings_manager.dart';
import 'package:yaga/model/preferences/mapping_preference.dart';
import 'package:yaga/model/preferences/uri_preference.dart';
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
  UriPreference _remote;
  UriPreference _local;

  @override
  void initState() {
    this._remote = widget.pref.remote;
    this._local = widget.pref.local;

    getIt
        .get<SettingsManager>()
        .updateSettingCommand
        .where((event) =>
            event.key == widget.pref.remote.key ||
            event.key == widget.pref.local.key)
        .map((event) => event as UriPreference)
        .listen((pref) {
      if (pref.key.endsWith("remote")) {
        _remote = pref;
      } else {
        _local = pref;
      }
    });

    super.initState();
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
            //todo: onCommit should return a list of all preferences then we do not need to listen here to the UriPref changes
            onCommit: () {
              Navigator.pop(context);
              getIt.get<SettingsManager>().persistMappingPreferenceCommand(
                    pref.rebuild((b) => b
                      ..local = _local.toBuilder()
                      ..remote = _remote.toBuilder()),
                  );
            },
          ),
        ),
      ),
    );
  }
}
