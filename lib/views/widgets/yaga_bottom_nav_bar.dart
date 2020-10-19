import 'package:flutter/material.dart';
import 'package:yaga/managers/tab_manager.dart';
import 'package:yaga/utils/service_locator.dart';
import 'package:yaga/views/screens/yaga_home_screen.dart';

class YagaBottomNavBar extends StatelessWidget {
  final YagaHomeTab _selectedTab;

  YagaBottomNavBar(this._selectedTab);

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: _getCurrentIndex(),
      onTap: (index) {
        Navigator.popUntil(context, ModalRoute.withName(YagaHomeScreen.route));

        if (index == _getCurrentIndex()) {
          return;
        }

        switch (index) {
          case 1:
            getIt.get<TabManager>().tabChangedCommand(YagaHomeTab.folder);
            return;
          default:
            getIt.get<TabManager>().tabChangedCommand(YagaHomeTab.grid);
        }
      },
      items: const <BottomNavigationBarItem>[
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home View',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.folder),
          label: 'Browse View',
        ),
      ],
    );
  }

  int _getCurrentIndex() {
    switch (this._selectedTab) {
      case YagaHomeTab.folder:
        return 1;
      default:
        return 0;
    }
  }
}
