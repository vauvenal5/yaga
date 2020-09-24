import 'package:flutter/material.dart';
import 'package:yaga/model/nc_file.dart';
import 'package:yaga/model/preference.dart';
import 'package:yaga/views/widgets/category_widget.dart';
import 'package:yaga/views/widgets/image_views/category_view.dart';
import 'package:yaga/managers/widget_local/file_list_local_manager.dart';

class ImageSearch extends SearchDelegate {

  final FileListLocalManager _fileListLocalManager;
  final BoolPreference _experimental;

  ImageSearch(this._fileListLocalManager, this._experimental);

  @override
  ThemeData appBarTheme(BuildContext context) {
    //todo: keep track of this issue and improve: https://github.com/flutter/flutter/issues/45498
    assert(context != null);
    final ThemeData theme = Theme.of(context);
    assert(theme != null);
    return theme.copyWith(
      inputDecorationTheme: InputDecorationTheme(hintStyle: TextStyle(color: theme.primaryTextTheme.headline.color)),
      textTheme: theme.textTheme.copyWith(
        headline: theme.textTheme.headline.copyWith(color: theme.primaryTextTheme.headline.color),
        title: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.normal,
          fontSize: 18,
        ),
      )
    );
  }

  @override
  List<Widget> buildActions(BuildContext context) {
    return <Widget>[
      IconButton(icon: Icon(Icons.close), onPressed: () => query="")
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(icon: Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context));
  }

  @override
  Widget buildResults(BuildContext context) {
    return CategoryView(
      this._fileListLocalManager, 
      _experimental, 
      filter: (List<NcFile> files) => files.where((file) => file.lastModified.toString().contains(this.query)).toList()
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return ListView(children: [],);
  }

}