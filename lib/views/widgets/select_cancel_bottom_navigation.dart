import 'package:flutter/material.dart';

class SelectCancelBottomNavigation extends StatelessWidget {
  final Function onCommit;
  final Function onCancel;
  final String labelSelect;
  final String labelCancel;
  final IconData iconSelect;
  final List<BottomNavigationBarItem> betweenItems;
  final List<Function> betweenItemsCallbacks;

  const SelectCancelBottomNavigation({
    required this.onCommit,
    required this.onCancel,
    this.labelSelect = "Select",
    this.labelCancel = "Cancel",
    this.iconSelect = Icons.check,
    this.betweenItems = const [],
    this.betweenItemsCallbacks = const [],
  });

  @override
  Widget build(BuildContext context) {
    final List<BottomNavigationBarItem> items = [];
    items.add(BottomNavigationBarItem(
      icon: const Icon(Icons.close),
      label: labelCancel,
    ));
    items.addAll(betweenItems);
    items.add(BottomNavigationBarItem(
      icon: Icon(iconSelect),
      label: labelSelect,
    ));

    return BottomNavigationBar(
      currentIndex: items.length - 1,
      onTap: (index) {
        if (index == items.length - 1) {
          onCommit();
          return;
        }

        if (index == 0) {
          onCancel();
          return;
        }

        final betweenItemsIndex = index - 1;
        if (betweenItemsIndex >= 0) {
          betweenItemsCallbacks[betweenItemsIndex].call();
          return;
        }
      },
      items: items,
    );
  }
}
