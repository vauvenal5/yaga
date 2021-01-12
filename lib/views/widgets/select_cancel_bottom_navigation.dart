import 'package:flutter/material.dart';

class SelectCancelBottomNavigation extends StatelessWidget {
  final Function onCommit;
  final Function onCancel;
  final String labelSelect;
  final String labelCancel;
  final IconData iconSelect;

  SelectCancelBottomNavigation({
    @required this.onCommit,
    @required this.onCancel,
    this.labelSelect = "Select",
    this.labelCancel = "Cancel",
    this.iconSelect = Icons.check,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: 1,
      onTap: (index) {
        if (index == 1) {
          this.onCommit();
          return;
        }

        this.onCancel();
      },
      items: <BottomNavigationBarItem>[
        BottomNavigationBarItem(
          icon: Icon(Icons.close),
          label: this.labelCancel,
        ),
        BottomNavigationBarItem(
          icon: Icon(this.iconSelect),
          label: this.labelSelect,
        ),
      ],
    );
  }
}
