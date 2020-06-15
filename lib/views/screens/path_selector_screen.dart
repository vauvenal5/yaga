import 'dart:io';

import 'package:flutter/material.dart';
import 'package:yaga/model/nc_file.dart';
import 'package:yaga/utils/path_selector_screen_arguments.dart';
import 'package:yaga/views/widgets/folder_widget.dart';
import 'package:yaga/views/widgets/path_widget.dart';

//todo: rename this since it is also used for browse view... maybe clean up a little
class PathSelectorScreen extends StatelessWidget {
  static const String route = "/pathSelector";

  final Uri _uri;
  final void Function() _onCancel;
  final void Function(Uri) _onSelect;
  final void Function(List<NcFile>, int) onFileTap;
  final String title;

  PathSelectorScreen(this._uri, this._onCancel, this._onSelect, {this.onFileTap, this.title});

  void _navigateToSelf(BuildContext context, Uri path) {
    Navigator.pushNamed(context, PathSelectorScreen.route, arguments: PathSelectorScreenArguments(
      uri: path, 
      onCancel: _onCancel, 
      onSelect: _onSelect,
      onFileTap: onFileTap
    ));
  }

  void _popUntilSelf(BuildContext context, Uri path) {
    Navigator.popUntil(context, (route) {
      if(route.settings.arguments is PathSelectorScreenArguments) {
        PathSelectorScreenArguments args = route.settings.arguments as PathSelectorScreenArguments;
        if(args.uri.toString() == path.toString()) {
          return true;
        }

        if(args.uri.scheme != path.scheme && args.uri.path == "/") {
          return true;
        }
      }

      return false;
    });

    if(_uri.scheme != path.scheme) {
      Navigator.pushReplacementNamed(context, PathSelectorScreen.route, arguments: PathSelectorScreenArguments(
        uri: path, 
        onCancel: _onCancel, 
        onSelect: _onSelect,
        onFileTap: onFileTap
      ));
    }
  }

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

    return Scaffold(
      appBar: AppBar(
        title: Text(this.title??"Select path..."),
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
              child: PathWidget(this._uri, (Uri subPath) => this._popUntilSelf(context, subPath))
            )
          ), 
          preferredSize: Size.fromHeight(40)
        ),
      ),
      //todo: is it possible to directly pass the folder.uri?
      body: FolderWidget(this._uri, onFolderTap: (NcFile folder) => this._navigateToSelf(context, folder.uri), onFileTap: this.onFileTap,),
      bottomNavigationBar: bottomBar,
    );
  }
}