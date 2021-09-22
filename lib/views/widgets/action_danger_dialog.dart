import 'package:flutter/material.dart';

class ActionDangerDialog extends StatelessWidget {
  final String title;
  final String cancelButton;
  final String normalAction;
  final String aggressiveAction;
  final Function(bool) action;
  final List<Widget> Function(BuildContext) bodyBuilder;

  const ActionDangerDialog({
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
        onPressed: () {
          Navigator.pop(context);
        },
        child: Text(cancelButton),
      ),
    );

    if (normalAction != null) {
      actions.add(
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            action(false);
          },
          child: Text(normalAction),
        ),
      );
    }

    actions.add(
      TextButton(
        style: TextButton.styleFrom(primary: Colors.red),
        onPressed: () {
          Navigator.pop(context);
          action(true);
        },
        child: Text(aggressiveAction),
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
