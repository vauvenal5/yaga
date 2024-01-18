import 'package:flutter/material.dart';
import 'package:yaga/model/nc_file.dart';
import 'package:yaga/views/widgets/favorite_icon.dart';

class FolderIcon extends StatelessWidget {
  final NcFile dir;
  final double size;

  const FolderIcon({super.key, required this.dir, this.size = 48});

  @override
  Widget build(BuildContext context) {
    Stack stack = Stack(children: [
      Icon(
        Icons.folder,
        size: size,
      ),
    ]);

    if (dir.favorite) {
      stack.children.add(FavoriteIcon());
    }

    return SizedBox(
      height: size,
      width: size,
      child: stack,
    );
  }
}
