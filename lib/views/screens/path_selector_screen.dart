import 'dart:io';

import 'package:flutter/material.dart';
import 'package:yaga/model/nc_file.dart';
import 'package:yaga/utils/path_selector_screen_arguments.dart';
import 'package:yaga/views/widgets/folder_widget.dart';
import 'package:yaga/views/widgets/path_widget.dart';

class PathSelectorScreen extends StatelessWidget {
  static const String route = "/pathSelector";

  final String _path;
  final void Function() _onCancel;
  final void Function(String) _onSelect;

  PathSelectorScreen(this._path, this._onCancel, this._onSelect) {
    print(_path);
  }

  void _navigateToSelf(BuildContext context, String path) {
    path = _path.startsWith("nc:")?"nc:$path":path;
    Navigator.pushNamed(context, PathSelectorScreen.route, arguments: PathSelectorScreenArguments(path, _onCancel, _onSelect));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Select path..."),
        // title: DropdownButton(
        //   value: this._path.split("/").last,
        //   onChanged: (String value) => Navigator.pushNamed(context, PathSelectorPage.route, arguments: this._path.split("/"+value).first),
        //   items: this._path.split("/").map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
        // ),
        bottom: PreferredSize(
          child: Container(
            height: 40,
            // padding: EdgeInsets.only(bottom: 10),
            child: Align(
              alignment: Alignment.topLeft,
              child: PathWidget(this._path, (subPath) => this._navigateToSelf(context, subPath))
            )
          ), 
          preferredSize: Size.fromHeight(40)
        ),
      ),
      body: FolderWidget(this._path, (NcFile folder) => this._navigateToSelf(context, folder.path)),
      bottomNavigationBar: ButtonBar(
        children: <Widget>[
          OutlineButton(
            onPressed: () => _onCancel(),
            child: Text("Cancel"),
          ),
          RaisedButton(
            onPressed: () => _onSelect(this._path),
            color: Theme.of(context).accentColor,
            child: Text("Select"),
          )
        ],
      )
    );
  }
}