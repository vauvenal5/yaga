import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:yaga/managers/settings_manager.dart';
import 'package:yaga/model/preference.dart';
import 'package:yaga/utils/service_locator.dart';

class PreferenceListTileWidget<T extends Preference> extends StatelessWidget {

  final T initData;
  final Widget Function(BuildContext, T) listTileBuilder;

  PreferenceListTileWidget({@required this.initData, @required this.listTileBuilder});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<T>(
      stream: getIt.get<SettingsManager>().updateSettingCommand
        .where((event) => event.key == this.initData.key)
        .map((event) => event as T),
      initialData: initData,
      builder: (BuildContext context, AsyncSnapshot<T> snapshot) {
        return listTileBuilder(context, snapshot.data);
      },
    );
  }

}