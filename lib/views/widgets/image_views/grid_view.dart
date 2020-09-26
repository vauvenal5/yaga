import 'package:flutter/material.dart';
import 'package:yaga/model/nc_file.dart';
import 'package:yaga/model/route_args/image_screen_arguments.dart';
import 'package:yaga/views/screens/image_screen.dart';
import 'package:yaga/views/widgets/remote_image_widget.dart';

class GridViewWidget extends StatelessWidget {
  static const String viewKey = "grid";
  final List<NcFile> _files;

  GridViewWidget(List<NcFile> files) : _files = files.where((file) => !file.isDirectory).toList();

  Widget _buildImage(int key, BuildContext context) {
    return InkWell(
      onTap: () => Navigator.pushNamed(context, ImageScreen.route, arguments: ImageScreenArguments(
        this._files, 
        key
      )),
      child: RemoteImageWidget(
        this._files[key], 
        key: ValueKey(this._files[key].uri.path), 
        cacheWidth: 256,
        // cacheHeight: 256, 
      ),
    );
  }

  void _sort() {
    _files.sort((a,b) => b.lastModified.compareTo(a.lastModified));
  }
  
  @override
  Widget build(BuildContext context) {
    _sort();

    return CustomScrollView(
      physics: AlwaysScrollableScrollPhysics(),
      slivers: <Widget>[
        SliverGrid(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 2,
            mainAxisSpacing: 2,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, index) => _buildImage(index, context),
            childCount: _files.length
          )
        ),
      ],
    );
  }

}