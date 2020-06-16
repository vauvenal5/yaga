import 'package:yaga/model/nc_file.dart';

class ImageScreenArguments {
  final List<NcFile> images;
  final int index;
  final String title;

  ImageScreenArguments(this.images, this.index, {this.title});
}