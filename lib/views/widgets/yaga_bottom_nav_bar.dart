import 'package:flutter/material.dart';
import 'package:yaga/managers/tab_manager.dart';
import 'package:yaga/utils/service_locator.dart';
import 'package:yaga/views/screens/yaga_home_screen.dart';

class YagaBottomNavBar extends StatelessWidget {
  final YagaHomeTab _selectedTab;

  const YagaBottomNavBar(this._selectedTab);

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: _getCurrentIndex(),
      onTap: (index) {
        switch (index) {
          case 2:
            getIt.get<TabManager>().tabChangedCommand(YagaHomeTab.folder);
            return;
          case 1:
            getIt.get<TabManager>().tabChangedCommand(YagaHomeTab.favorites);
            return;
          default:
            getIt.get<TabManager>().tabChangedCommand(YagaHomeTab.grid);
        }
      },
      items: const <BottomNavigationBarItem>[
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.star),
          label: 'Favorites',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.folder),
          label: 'Browse',
        ),
      ],
    );
  }

  int _getCurrentIndex() {
    switch (_selectedTab) {
      case YagaHomeTab.folder:
        return 2;
      case YagaHomeTab.favorites:
        return 1;
      default:
        return 0;
    }
  }
}
