import 'dart:io';

import 'package:flutter/material.dart';
import 'package:yaga/model/nc_file.dart';
import 'package:yaga/model/route_args/directory_navigation_arguments.dart';
import 'package:yaga/model/route_args/navigatable_screen_arguments.dart';
import 'package:yaga/views/widgets/folder_widget.dart';
import 'package:yaga/views/widgets/path_widget.dart';

//todo: rename this since it is also used for browse view... maybe clean up a little
class DirectoryNavigationScreen extends StatelessWidget {
  static const String route = "/directoryNavigationScreen";

  final Uri uri;
  final void Function(List<NcFile>, int) onFileTap;
  final String title;
  final Widget Function(BuildContext, Uri) bottomBarBuilder;

  DirectoryNavigationScreen({@required this.uri, this.onFileTap, this.title, this.bottomBarBuilder});

  DirectoryNavigationArguments _getSelfArgs(Uri path) {
    return DirectoryNavigationArguments(
      uri: path, 
      onFileTap: this.onFileTap,
      title: this.title,
      bottomBarBuilder: this.bottomBarBuilder
    );
  }

  void _navigateToSelf(BuildContext context, Uri path) {
    Navigator.pushNamed(context, DirectoryNavigationScreen.route, arguments: _getSelfArgs(path));
  }

  void _popUntilSelf(BuildContext context, Uri path) {
    Navigator.popUntil(context, (route) {
      if(route.settings.arguments is NavigatableScreenArguments) {
        NavigatableScreenArguments args = route.settings.arguments as NavigatableScreenArguments;
        if(args.uri.toString() == path.toString()) {
          return true;
        }

        if(args.uri.scheme != path.scheme && args.uri.path == "/") {
          return true;
        }
      }

      return false;
    });

    if(uri.scheme != path.scheme) {
      Navigator.pushReplacementNamed(context, DirectoryNavigationScreen.route, arguments: _getSelfArgs(path));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(this.title??uri.pathSegments.last),
        bottom: PreferredSize(
          child: Container(
            height: 40,
            child: Align(
              alignment: Alignment.topLeft,
              child: PathWidget(this.uri, (Uri subPath) => this._popUntilSelf(context, subPath))
            )
          ), 
          preferredSize: Size.fromHeight(40)
        ),
      ),
      //todo: is it possible to directly pass the folder.uri?
      body: FolderWidget(this.uri, onFolderTap: (NcFile folder) => this._navigateToSelf(context, folder.uri), onFileTap: this.onFileTap,),
      bottomNavigationBar: bottomBarBuilder == null ? null : bottomBarBuilder(context, uri),
    );
  }
}