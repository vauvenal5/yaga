import 'package:flutter/material.dart';

class ActionDangerDialog extends StatelessWidget {
  final String title;
  final String cancelButton;
  final String normalAction;
  final String aggressiveAction;
  final Function(bool) action;
  final List<Widget> Function(BuildContext) bodyBuilder;

  ActionDangerDialog({
    @required this.title,
    @required this.cancelButton,
    this.normalAction,
    @required this.aggressiveAction,
    @required this.action,
    @required this.bodyBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final actions = <Widget>[];

    actions.add(
      TextButton(
        child: Text(cancelButton),
        onPressed: () {
          Navigator.pop(context);
        },
      ),
    );

    if (normalAction != null) {
      actions.add(
        TextButton(
          child: Text(normalAction),
          onPressed: () {
            Navigator.pop(context);
            action(false);
          },
        ),
      );
    }

    actions.add(
      TextButton(
        child: Text(aggressiveAction),
        style: TextButton.styleFrom(primary: Colors.red),
        onPressed: () {
          Navigator.pop(context);
          action(true);
        },
      ),
    );

    return AlertDialog(
      title: Text(title),
      content: SingleChildScrollView(
        child: ListBody(
          children: bodyBuilder(context),
        ),
      ),
      actions: actions,
    );
  }
}
