import 'package:flutter/material.dart';
import 'package:rx_command/rx_command.dart';
import 'package:yaga/managers/settings_manager.dart';
import 'package:yaga/model/preference.dart';
import 'package:yaga/model/route_args/path_selector_screen_arguments.dart';
import 'package:yaga/services/shared_preferences_service.dart';
import 'package:yaga/utils/service_locator.dart';
import 'package:yaga/utils/uri_utils.dart';
import 'package:yaga/views/screens/path_selector_screen.dart';
import 'package:yaga/views/screens/settings_screen.dart';
import 'package:yaga/views/widgets/preferences/preference_list_tile_widget.dart';

class UriPreferenceWidget extends StatelessWidget{
  final UriPreference _defaultPref;
  final RxCommand<Preference, dynamic> onChangeCommand;

  UriPreferenceWidget(this._defaultPref, {this.onChangeCommand});

  Uri _buildSubUri(Uri uri, String segment) {
    String path = "";
    int index = uri.pathSegments.indexOf(segment);
    for(int i =0;i<=index;i++) {
      path += "/${uri.pathSegments[i]}";
    }
    return UriUtils.fromUri(uri: uri, path: path);
  }

  void _notifyChange(UriPreference pref) {
    if(onChangeCommand != null) {
      onChangeCommand(pref);
      return;
    }
    getIt.get<SettingsManager>().persistUriSettingCommand(pref);
  }

  void _pushToNavigation(BuildContext context, UriPreference pref, Uri uri) {
    Navigator.pushNamed(
      context, 
      PathSelectorScreen.route, 
      arguments: PathSelectorScreenArguments(
        uri: uri,
        onCancel: () => Navigator.popUntil(context, ModalRoute.withName(SettingsScreen.route)), 
        onSelect: (Uri path) {
          Navigator.popUntil(context, ModalRoute.withName(SettingsScreen.route));
          _notifyChange(UriPreference(pref.key, pref.title, path));
        }
      )
    );
  }

  //todo: track issue https://github.com/flutter/flutter/issues/45938 and improve this madness when possible
  void _pushViews(BuildContext context, UriPreference pref) {
    Uri uri = pref.value;
    _pushToNavigation(context, pref, UriUtils.fromUri(uri: uri, path: "/"));
    for(String segment in uri.pathSegments) {
      _pushToNavigation(context, pref, _buildSubUri(uri, segment));
    }
  }

  @override
  Widget build(BuildContext context) {
    return PreferenceListTileWidget<UriPreference>(
      initData: getIt.get<SharedPreferencesService>().loadUriPreference(_defaultPref), 
      listTileBuilder: (context, pref) => ListTile(
        title: Text(pref.title),
        subtitle: Text(pref.value.toString()),
        onTap: () => _pushViews(context, pref),
      )
    );
  }

}