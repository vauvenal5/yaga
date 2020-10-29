import 'package:flutter/material.dart';
import 'package:yaga/model/nc_file.dart';

class ImageScreenArguments {
  final List<NcFile> images;
  final int index;
  final String title;
  final IconButton Function(BuildContext, NcFile) mainActionBuilder;

  ImageScreenArguments(this.images, this.index,
      {this.title, this.mainActionBuilder});
}
