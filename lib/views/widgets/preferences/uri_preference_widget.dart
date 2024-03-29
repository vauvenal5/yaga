import 'package:flutter/material.dart';
import 'package:rx_command/rx_command.dart';
import 'package:yaga/managers/settings_manager.dart';
import 'package:yaga/model/preferences/preference.dart';
import 'package:yaga/model/preferences/uri_preference.dart';
import 'package:yaga/model/route_args/path_selector_screen_arguments.dart';
import 'package:yaga/services/name_exchange_service.dart';
import 'package:yaga/services/shared_preferences_service.dart';
import 'package:yaga/utils/service_locator.dart';
import 'package:yaga/views/screens/path_selector_screen.dart';
import 'package:yaga/views/widgets/preferences/preference_list_tile_widget.dart';

class UriPreferenceWidget extends StatelessWidget {
  final UriPreference _defaultPref;
  final RxCommand<Preference, dynamic>? onChangeCommand;

  const UriPreferenceWidget(this._defaultPref, {this.onChangeCommand});

  void _notifyChange(UriPreference pref) {
    if (onChangeCommand != null) {
      onChangeCommand!(pref);
      return;
    }
    getIt.get<SettingsManager>().persistStringSettingCommand(pref);
  }

  void _pushToNavigation(BuildContext context, UriPreference pref, Uri uri) {
    Navigator.pushNamed(
      context,
      PathSelectorScreen.route,
      arguments: PathSelectorScreenArguments(
        uri: uri,
        onSelect: (Uri path) => _notifyChange(
          pref.rebuild((b) => b..value = path),
        ),
        fixedOrigin: pref.fixedOrigin,
        schemeFilter: pref.schemeFilter,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PreferenceListTileWidget<UriPreference>(
      initData: getIt
          .get<SharedPreferencesService>()
          .loadPreferenceFromString(_defaultPref),
      listTileBuilder: (context, pref) => ListTile(
        enabled: pref.enabled!,
        title: Text(pref.title!),
        subtitle: Text(Uri.decodeComponent(getIt.get<NameExchangeService>().convertUriToHumanReadableUri(pref.value).toString())),
        onTap: () => _pushToNavigation(context, pref, pref.value),
      ),
    );
  }
}
