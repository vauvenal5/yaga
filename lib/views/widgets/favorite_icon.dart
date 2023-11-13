import 'package:flutter/material.dart';
import 'package:yaga/views/widgets/circle_avatar_icon.dart';

class FavoriteIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Align(
      alignment: Alignment.bottomLeft,
      child: CircleAvatarIcon(
        icon: Icon(
          Icons.star,
          color: Colors.amber,
        ),
      ),
    );
  }

}