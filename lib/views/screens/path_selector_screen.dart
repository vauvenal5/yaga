import 'package:flutter/material.dart';
import 'package:yaga/model/nc_file.dart';
import 'package:yaga/model/route_args/directory_navigation_screen_arguments.dart';
import 'package:yaga/model/route_args/path_selector_screen_arguments.dart';
import 'package:yaga/views/screens/directory_navigation_screen.dart';
import 'package:yaga/views/widgets/ok_cancel_button_bar.dart';

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
      bottomBarBuilder = (BuildContext context, Uri uri) => OkCancelButtonBar(onCommit: () => _onSelect(uri), onCancel: () => _onCancel());
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