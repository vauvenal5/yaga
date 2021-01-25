import 'package:flutter/material.dart';

class SelectionActionCancelDialog extends StatelessWidget {
  final String title;
  final Function() cancelAction;

  SelectionActionCancelDialog(this.title, this.cancelAction);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(this.title),
      content: SingleChildScrollView(
        child: Center(
          child: CircularProgressIndicator(),
        ),
      ),
      actions: [
        TextButton(
          child: Text('Cancel'),
          onPressed: () => cancelAction(),
        ),
      ],
    );
  }
}
