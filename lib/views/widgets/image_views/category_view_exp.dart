import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:sticky_infinite_list/sticky_infinite_list.dart';
import 'package:yaga/model/sorted_category_list.dart';
import 'package:yaga/utils/logger.dart';
import 'package:yaga/views/widgets/image_views/utils/view_configuration.dart';
import 'package:yaga/views/widgets/remote_image_widget.dart';

class CategoryViewExp extends StatelessWidget {
  final _logger = YagaLogger.getLogger(CategoryViewExp);
  static const String viewKey = "category_exp";
  final ViewConfiguration viewConfig;
  final SortedCategoryList sorted;

  CategoryViewExp(this.sorted, this.viewConfig);

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

  Widget _buildExperimental() {
    final ScrollController scrollController = ScrollController();

    final InfiniteList infiniteList = InfiniteList(
        posChildCount: sorted.categories.length,
        controller: scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        builder: (BuildContext context, int indexCategory) {
          final String key = sorted.categories[indexCategory];

          /// Builder requires [InfiniteList] to be returned
          return InfiniteListItem(
            /// Header builder
            headerBuilder: (BuildContext context) {
              return _buildHeader(key, context);
            },

            /// Content builder
            contentBuilder: (BuildContext context) {
              return GridView.builder(
                  key: ValueKey("${key}_grid"),
                  controller: scrollController,
                  shrinkWrap: true,
                  itemCount: sorted.categorizedFiles[key]!.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 2,
                    mainAxisSpacing: 2,
                  ),
                  itemBuilder: (context, itemIndex) {
                    return _buildImage(key, itemIndex, context);
                  });
            },
          );
        });

    return infiniteList;
  }

  @override
  Widget build(BuildContext context) {
    _logger.finer("drawing list");

    return _buildExperimental();
  }
}
