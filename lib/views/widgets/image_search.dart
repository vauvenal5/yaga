import 'package:flutter/material.dart';
import 'package:yaga/model/nc_file.dart';
import 'package:yaga/model/preference.dart';
import 'package:yaga/views/widgets/category_widget.dart';

class ImageSearch extends SearchDelegate {

  final List<NcFile> sortedFiles;
  final BoolPreference _experimental;

  ImageSearch(this.sortedFiles, this._experimental);

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
    List<NcFile> filteredFiles = sortedFiles.where((file) => file.lastModified.toString().contains(this.query)).toList();
    return CategoryWidget(filteredFiles, _experimental);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return ListView(children: [],);
  }

}