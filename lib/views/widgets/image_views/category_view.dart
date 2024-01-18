import 'package:flutter/material.dart';
import 'package:flutter_sticky_header/flutter_sticky_header.dart';
import 'package:yaga/model/sorted_category_list.dart';
import 'package:yaga/utils/logger.dart';
import 'package:yaga/views/widgets/image_views/utils/grid_delegate.dart';
import 'package:yaga/views/widgets/image_views/utils/view_configuration.dart';
import 'package:yaga/views/widgets/remote_image_widget.dart';

class CategoryView extends StatelessWidget with GridDelegate {
  final _logger = YagaLogger.getLogger(CategoryView);
  static const String viewKey = "category";
  final ViewConfiguration viewConfig;
  final SortedCategoryList sorted;

  CategoryView(this.sorted, this.viewConfig);

  Widget _buildHeader(String key, BuildContext context) {
    return Container(
      height: 30.0,
      color: Theme.of(context).colorScheme.secondary,
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
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
        key: ValueKey("${key}_grid"),
        delegate: SliverChildBuilderDelegate((BuildContext context, int index) {
          return _buildImage(key, index, context);
        }, childCount: sorted.categorizedFiles[key]!.length),
        gridDelegate: buildImageGridDelegate(context),
      ),
    );
  }

  Widget _buildImage(String key, int itemIndex, BuildContext context) {
    return InkWell(
      onTap: () =>
          viewConfig.onFileTap?.call(sorted.categorizedFiles[key]!, itemIndex),
      onLongPress: () =>
          viewConfig.onSelect?.call(sorted.categorizedFiles[key]!, itemIndex),
      child: RemoteImageWidget(
        sorted.categorizedFiles[key]![itemIndex],
        key: ValueKey(sorted.categorizedFiles[key]![itemIndex].uri.path),
        cacheWidth: 512,
      ),
    );
  }

  Widget _buildStickyList(BuildContext context) {
    final List<Widget> slivers = [];

    //todo: the actual issue behind the performance problems is that for many categorise we are keepint all headers in memory at once and also a tone of images
    //--> it seems the headerSliver is not cleaning up properly
    //--> long terme we need to find a solution for this!
    for (final key in sorted.categories) {
      print("rebuilding list");
      slivers.add(_buildCategory(key, context));
    }

    final DefaultStickyHeaderController sticky = DefaultStickyHeaderController(
        key: const ValueKey("mainGrid"),
        child: CustomScrollView(
          key: const ValueKey("mainGridView"),
          slivers: slivers,
          physics: const AlwaysScrollableScrollPhysics(),
        ));

    return sticky;
  }

  @override
  Widget build(BuildContext context) {
    _logger.finer("drawing list");

    return _buildStickyList(context);
  }
}
