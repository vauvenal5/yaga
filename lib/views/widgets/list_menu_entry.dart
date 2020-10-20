import 'package:flutter/material.dart';

class ListMenuEntry extends StatelessWidget {
  final IconData _iconData;
  final String _text;

  ListMenuEntry(this._iconData, this._text);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(_iconData),
      title: Text(_text),
      isThreeLine: false,
      contentPadding: EdgeInsets.all(0),
    );
  }
}
