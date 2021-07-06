import 'dart:io';

import 'package:flutter/material.dart';
import 'package:yaga/managers/settings_manager.dart';
import 'package:yaga/model/preferences/bool_preference.dart';
import 'package:yaga/model/preferences/mapping_preference.dart';
import 'package:yaga/model/preferences/preference.dart';
import 'package:yaga/model/preferences/uri_preference.dart';
import 'package:yaga/model/route_args/settings_screen_arguments.dart';
import 'package:yaga/services/isolateable/system_location_service.dart';
import 'package:yaga/services/shared_preferences_service.dart';
import 'package:yaga/utils/service_locator.dart';
import 'package:yaga/views/screens/settings_screen.dart';
import 'package:yaga/views/widgets/preferences/preference_list_tile_widget.dart';
import 'package:yaga/views/widgets/action_danger_dialog.dart';

class MappingPreferenceWidget extends StatefulWidget {
  final MappingPreference pref;
  final String route;

  const MappingPreferenceWidget(this.pref, this.route);

  @override
  State<StatefulWidget> createState() => _MappingPreferenceState();
}

class _MappingPreferenceState extends State<MappingPreferenceWidget> {
  SystemLocationService _systemLocationService;
  UriPreference _remote;
  UriPreference _local;
  BoolPreference _syncDeletes;

  @override
  void initState() {
    _systemLocationService = getIt.get<SystemLocationService>();
    final _settingsManager = getIt.get<SettingsManager>();

    final prefService = getIt.get<SharedPreferencesService>();
    _remote = prefService.loadPreferenceFromString(widget.pref.remote);
    _local = prefService.loadPreferenceFromString(widget.pref.local);
    _syncDeletes = prefService.loadPreferenceFromBool(
      widget.pref.syncDeletes,
    );

    _settingsManager.updateSettingCommand
        .where(
      (event) =>
          event.key == widget.pref.remote.key ||
          event.key == widget.pref.local.key ||
          event.key == widget.pref.syncDeletes.key,
    )
        .listen((pref) {
      if (pref.key == _remote.key) {
        _remote = pref as UriPreference;
      }

      if (pref.key == _local.key) {
        _local = pref as UriPreference;
        _settingsManager.updateSettingCommand(
          _syncDeletes.rebuild((b) => b..value = false),
        );
      }

      if (pref.key == _syncDeletes.key) {
        _syncDeletes = pref as BoolPreference;
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
            preferences: [pref.remote, pref.local, pref.syncDeletes],
            onCancel: () => Navigator.pop(context),
            //todo: onCommit should return a list of all preferences then we do not need to listen here to the UriPref changes
            onCommit: () => _checkDirectory(context, pref),
          ),
        ),
      ),
    );
  }

  void _checkDirectory(BuildContext context, MappingPreference pref) {
    if (_syncDeletes.value &&
        Directory(_systemLocationService
                .absoluteUriFromInternal(_local.value)
                .path)
            .listSync()
            .isNotEmpty) {
      showDialog(
        context: context,
        builder: (context) => ActionDangerDialog(
          title: "Danger of losing data",
          cancelButton: "Cancel",
          aggressiveAction: "Continue",
          action: (agg) {
            Navigator.pop(context);
            if (agg) {
              _persist(context, pref);
            }
          },
          bodyBuilder: (context) => <Widget>[
            const Text(
              'The choosen local directory is not empty. Any files which do not exist on the Nextcloud side of the mapping will be erased from your phone!',
            ),
          ],
        ),
      );
    } else {
      _persist(context, pref);
    }
  }

  void _persist(BuildContext context, MappingPreference pref) {
    Navigator.pop(context);
    getIt.get<SettingsManager>().persistMappingPreferenceCommand(
          pref.rebuild(
            (b) => b
              ..local = _local.toBuilder()
              ..remote = _remote.toBuilder()
              ..syncDeletes = _syncDeletes.toBuilder(),
          ),
        );
  }
}
