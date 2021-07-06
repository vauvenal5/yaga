import 'package:flutter/material.dart';

class SelectionActionCancelDialog extends StatelessWidget {
  final String title;
  final Function() cancelAction;

  const SelectionActionCancelDialog(this.title, this.cancelAction);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: const SingleChildScrollView(
        child: Center(
          child: CircularProgressIndicator(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => cancelAction(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
