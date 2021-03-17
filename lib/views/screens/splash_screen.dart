import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:yaga/utils/nextcloud_colors.dart';

class SplashScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var scaffold = Scaffold(
      backgroundColor: Colors.transparent,
      body: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.max,
        children: <Widget>[
          Align(
            alignment: Alignment.center,
            child: SvgPicture.asset(
              "assets/icon/foreground.svg",
              semanticsLabel: 'Yaga Logo',
              alignment: Alignment.center,
              width: 108,
            ),
          ),
        ],
      ),
    );

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            NextcloudColors.lightBlue,
            NextcloudColors.darkBlue,
          ],
        ),
      ),
      child: scaffold,
    );
  }
}
