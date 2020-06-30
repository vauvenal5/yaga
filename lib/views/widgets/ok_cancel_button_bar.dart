import 'package:flutter/material.dart';

class OkCancelButtonBar extends StatelessWidget {
  Function onCommit;
  Function onCancel;

  OkCancelButtonBar({@required this.onCommit, @required this.onCancel});

  @override
  Widget build(BuildContext context) {
    return ButtonBar(
      children: <Widget>[
        OutlineButton(
          onPressed: () => onCancel(),
          child: Text("Cancel"),
        ),
        RaisedButton(
          onPressed: () => onCommit(),
          color: Theme.of(context).accentColor,
          //todo: make text changeable
          child: Text("Select"),
        )
      ],
    );
  }

}