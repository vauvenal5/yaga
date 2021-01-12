import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_sticky_header/flutter_sticky_header.dart';
import 'package:yaga/model/nc_file.dart';
import 'package:yaga/views/widgets/image_views/utils/view_configuration.dart';
import 'package:yaga/views/widgets/remote_image_widget.dart';

class CategoryView extends StatelessWidget {
  static const String viewKey = "category";
  final ViewConfiguration viewConfig;
  final List<DateTime> dates = [];
  final List<NcFile> files;
  final Map<String, List<NcFile>> sortedFiles = Map();

  CategoryView(this.files, this.viewConfig);

  Widget _buildHeader(String key, BuildContext context) {
    return Container(
      height: 30.0,
      color: Theme.of(context).accentColor,
      padding: EdgeInsets.symmetric(horizontal: 16.0),
      alignment: Alignment.centerLeft,
      child: Text(
        key,
        style: const TextStyle(color: Colors.white),
      ),
    );
  }

  SliverStickyHeader _buildCategory(String key, BuildContext context) {
    return SliverStickyHeader(
        key: ValueKey(key),
        header: _buildHeader(key, context),
        sliver: SliverGrid(
            key: ValueKey(key + "_grid"),
            delegate:
                SliverChildBuilderDelegate((BuildContext context, int index) {
              return _buildImage(key, index, context);
              //return Image.file(_sortedFiles[key][index].localFile, cacheWidth: 64, key: ValueKey(_sortedFiles[key][index].uri.path),);
            }, childCount: this.sortedFiles[key].length),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 2,
              mainAxisSpacing: 2,
            )));
  }

  Widget _buildImage(String key, int itemIndex, BuildContext context) {
    return InkWell(
      onTap: () => this.viewConfig.onFileTap(this.sortedFiles[key], itemIndex),
      onLongPress: () =>
          this.viewConfig.onSelect(this.sortedFiles[key], itemIndex),
      child: RemoteImageWidget(
        this.sortedFiles[key][itemIndex],
        key: ValueKey(this.sortedFiles[key][itemIndex].uri.path),
        cacheWidth: 512,
      ),
    );
  }

  Widget _buildStickyList(BuildContext context) {
    List<Widget> slivers = [];

    //todo: the actual issue behind the performance problems is that for many categorise we are keepint all headers in memory at once and also a tone of images
    //--> it seems the headerSliver is not cleaning up properly
    //--> long terme we need to find a solution for this!
    this.dates.forEach((element) {
      print("rebuilding list");
      String key = _createKey(element);
      slivers.add(_buildCategory(key, context));
    });

    DefaultStickyHeaderController sticky = DefaultStickyHeaderController(
        key: ValueKey("mainGrid"),
        child: CustomScrollView(
          key: ValueKey("mainGridView"),
          slivers: slivers,
          physics: AlwaysScrollableScrollPhysics(),
        ));

    return sticky;
  }

  void _sort() {
    this.files.where((file) => !file.isDirectory).forEach((file) {
      DateTime lastModified = file.lastModified;
      DateTime date =
          DateTime(lastModified.year, lastModified.month, lastModified.day);

      if (!this.dates.contains(date)) {
        this.dates.add(date);
        this.dates.sort((date1, date2) => date2.compareTo(date1));
      }

      String key = _createKey(date);
      sortedFiles.putIfAbsent(key, () => []);
      //todo-sv: this has to be solved in a better way... double calling happens for example when in path selector screen navigating to same path
      //todo-sv: dart magic matches the files properly however it will be better to add a custom equals --> how does dart runtime hashcode work? Oo
      if (!sortedFiles[key].contains(file)) {
        sortedFiles[key].add(file);
        sortedFiles[key]
            .sort((a, b) => b.lastModified.compareTo(a.lastModified));
      }
    });
  }

  static String _createKey(DateTime date) => date.toString().split(" ")[0];

  @override
  Widget build(BuildContext context) {
    print("drawing list");

    _sort();

    return _buildStickyList(context);
  }
}
