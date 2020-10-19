import 'package:flutter/material.dart';
import 'package:yaga/views/screens/yaga_home_screen.dart';

class YagaBottomNavBar extends StatelessWidget {
  final YagaHomeTab _selectedTab;
  final void Function(YagaHomeTab) _onTabChanged;

  YagaBottomNavBar(this._selectedTab, this._onTabChanged);

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
            _onTabChanged(YagaHomeTab.folder);
            return;
          default:
            _onTabChanged(YagaHomeTab.grid);
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
