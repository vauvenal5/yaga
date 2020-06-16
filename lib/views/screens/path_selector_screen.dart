import 'package:flutter/material.dart';
import 'package:yaga/model/nc_file.dart';
import 'package:yaga/model/route_args/directory_navigation_screen_arguments.dart';
import 'package:yaga/model/route_args/path_selector_screen_arguments.dart';
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
    Widget Function(BuildContext, Uri) bottomBarBuilder;
    
    if(_onSelect != null || _onCancel != null) {
      bottomBarBuilder = (BuildContext context, Uri uri) => ButtonBar(
        children: <Widget>[
          OutlineButton(
            onPressed: () => _onCancel(),
            child: Text("Cancel"),
          ),
          RaisedButton(
            onPressed: () => _onSelect(uri),
            color: Theme.of(context).accentColor,
            child: Text("Select"),
          )
        ],
      );
    }

    return DirectoryNavigationScreen(
      uri: this._uri, 
      bottomBarBuilder: bottomBarBuilder, 
      onFileTap: this.onFileTap, 
      title: this.title??"Select path...",
      navigationRoute: PathSelectorScreen.route,
      getNavigationArgs: (DirectoryNavigationScreenArguments args) => PathSelectorScreenArguments(
        uri: args.uri, 
        onFileTap: args.onFileTap, 
        title: args.title,
        onCancel: this._onCancel,
        onSelect: this._onSelect
      ),
    );
  }
}