import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:sticky_infinite_list/sticky_infinite_list.dart';
import 'package:yaga/model/nc_file.dart';
import 'package:yaga/model/route_args/image_screen_arguments.dart';
import 'package:yaga/views/screens/image_screen.dart';
import 'package:yaga/views/widgets/remote_image_widget.dart';

class CategoryViewExp extends StatelessWidget {
  static const String viewKey = "category_exp";
  final List<DateTime> dates = [];
  final List<NcFile> files;
  final Map<String, List<NcFile>> sortedFiles = Map();

  CategoryViewExp(this.files);

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

  Widget _buildImage(String key, int itemIndex, BuildContext context) {
    return InkWell(
      onTap: () => Navigator.pushNamed(context, ImageScreen.route, arguments: ImageScreenArguments(
        this.sortedFiles[key], 
        itemIndex, 
        title: key
      )),
      child: RemoteImageWidget(
        this.sortedFiles[key][itemIndex], 
        key: ValueKey(this.sortedFiles[key][itemIndex].uri.path), 
        cacheWidth: 512, 
      ),
    );
  }

  Widget _buildExperimental() {
    ScrollController scrollController = ScrollController();

    InfiniteList infiniteList = InfiniteList(
      posChildCount: this.dates.length,
      controller: scrollController,
      physics: AlwaysScrollableScrollPhysics(),
      builder: (BuildContext context, int indexCategory) {
        String key = _createKey(this.dates[indexCategory]);
        /// Builder requires [InfiniteList] to be returned
        return InfiniteListItem(
          /// Header builder
          headerBuilder: (BuildContext context) {
            return _buildHeader(key, context);
          },
          /// Content builder
          contentBuilder: (BuildContext context) {
            return GridView.builder(
              key: ValueKey(key+"_grid"),
              controller: scrollController,
              shrinkWrap: true,
              itemCount: this.sortedFiles[key].length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 2,
                mainAxisSpacing: 2,
              ), 
              itemBuilder: (context, itemIndex) {
                return _buildImage(key, itemIndex, context);
              }
            );
          },
        );
      }
    );

    return infiniteList;
  }

  void _sort() {
    this.files.where((file) => !file.isDirectory)
    .forEach((file) {
      DateTime lastModified = file.lastModified;
      DateTime date = DateTime(lastModified.year, lastModified.month, lastModified.day);
      
      if(!this.dates.contains(date)) {
        this.dates.add(date);
        this.dates.sort((date1, date2) => date2.compareTo(date1));
      }

      String key = _createKey(date);
      sortedFiles.putIfAbsent(key, () => []);
      //todo-sv: this has to be solved in a better way... double calling happens for example when in path selector screen navigating to same path
      //todo-sv: dart magic matches the files properly however it will be better to add a custom equals --> how does dart runtime hashcode work? Oo
      if(!sortedFiles[key].contains(file)) {
        sortedFiles[key].add(file);
        sortedFiles[key].sort((a,b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      }
    });
  }

  static String _createKey(DateTime date) => date.toString().split(" ")[0];

  @override
  Widget build(BuildContext context) {
    print("drawing list");

    _sort();
    
    return _buildExperimental();
  }
}