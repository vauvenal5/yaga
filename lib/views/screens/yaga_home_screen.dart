import 'package:flutter/material.dart';
import 'package:yaga/managers/tab_manager.dart';
import 'package:yaga/utils/service_locator.dart';
import 'package:yaga/views/screens/home_view.dart';
import 'package:yaga/views/screens/browse_view.dart';

//todo: this has to be renamed
enum YagaHomeTab { grid, folder }

class YagaHomeScreen extends StatelessWidget {
  static const String route = "/";

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<YagaHomeTab>(
      initialData: YagaHomeTab.grid,
      stream: getIt.get<TabManager>().tabChangedCommand,
      builder: (context, snapshot) {
        return IndexedStack(
          index: this._getCurrentIndex(snapshot.data),
          children: <Widget>[HomeView(), BrowseView()],
        );
      },
    );
  }

  int _getCurrentIndex(YagaHomeTab tab) {
    switch (tab) {
      case YagaHomeTab.folder:
        return 1;
      default:
        return 0;
    }
  }
}
