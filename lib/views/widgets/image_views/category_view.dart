import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_sticky_header/flutter_sticky_header.dart';
import 'package:yaga/model/sorted_category_list.dart';
import 'package:yaga/views/widgets/image_views/utils/view_configuration.dart';
import 'package:yaga/views/widgets/remote_image_widget.dart';

class CategoryView extends StatelessWidget {
  static const String viewKey = "category";
  final ViewConfiguration viewConfig;
  final SortedCategoryList sorted;

  CategoryView(this.sorted, this.viewConfig);

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
            }, childCount: this.sorted.categorizedFiles[key].length),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 2,
              mainAxisSpacing: 2,
            )));
  }

  Widget _buildImage(String key, int itemIndex, BuildContext context) {
    return InkWell(
      onTap: () => this
          .viewConfig
          .onFileTap(this.sorted.categorizedFiles[key], itemIndex),
      onLongPress: () => this
          .viewConfig
          .onSelect(this.sorted.categorizedFiles[key], itemIndex),
      child: RemoteImageWidget(
        this.sorted.categorizedFiles[key][itemIndex],
        key: ValueKey(this.sorted.categorizedFiles[key][itemIndex].uri.path),
        cacheWidth: 512,
      ),
    );
  }

  Widget _buildStickyList(BuildContext context) {
    List<Widget> slivers = [];

    //todo: the actual issue behind the performance problems is that for many categorise we are keepint all headers in memory at once and also a tone of images
    //--> it seems the headerSliver is not cleaning up properly
    //--> long terme we need to find a solution for this!
    this.sorted.categories.forEach((key) {
      print("rebuilding list");
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

  @override
  Widget build(BuildContext context) {
    print("drawing list");

    return _buildStickyList(context);
  }
}
