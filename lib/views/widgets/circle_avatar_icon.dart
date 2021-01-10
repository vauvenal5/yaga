import 'package:flutter/material.dart';

class CircleAvatarIcon extends StatelessWidget {
  final Icon icon;
  final double radius;

  CircleAvatarIcon({@required this.icon, this.radius = 13});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: <Widget>[
        CircleAvatar(
          radius: this.radius,
          backgroundColor: Colors.white,
        ),
        this.icon,
      ],
    );
  }
}
