import 'package:flutter/material.dart';
import 'package:yaga/model/nc_file.dart';
import 'package:yaga/views/screens/directory_navigation_screen.dart';

class PathSelectorScreen extends StatelessWidget {
  static const String route = "/pathSelector";

  final Uri _uri;
  final void Function() _onCancel;
  final void Function(Uri) _onSelect;
  final void Function(List<NcFile>, int) onFileTap;
  final String title;

  PathSelectorScreen(this._uri, this._onCancel, this._onSelect, {this.onFileTap, this.title});

  @override
  Widget build(BuildContext context) {
    Widget bottomBar;
    if(_onSelect != null || _onCancel != null) {
      bottomBar = ButtonBar(
        children: <Widget>[
          OutlineButton(
            onPressed: () => _onCancel(),
            child: Text("Cancel"),
          ),
          RaisedButton(
            onPressed: () => _onSelect(this._uri),
            color: Theme.of(context).accentColor,
            child: Text("Select"),
          )
        ],
      );
    }

    return DirectoryNavigationScreen(uri: this._uri, bottomBar: bottomBar, onFileTap: this.onFileTap, title: this.title,);
  }
}