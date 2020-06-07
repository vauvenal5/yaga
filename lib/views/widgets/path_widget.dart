import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:yaga/managers/nextcloud_manager.dart';
import 'package:yaga/utils/service_locator.dart';
import 'package:yaga/views/widgets/avatar_widget.dart';

class PathWidget extends StatelessWidget {
  final List<String> _paths;
  final Function _onTap;

  PathWidget(String path, this._onTap) : _paths = path.split("/");

  String _subPath(int index) {
    String subPath = _paths[0]==""?"":"nc:";
    for(int i = 1; i<=index;i++) {
      subPath += "/"+_paths[i];
    }
    return subPath;
  }

  @override
  Widget build(BuildContext context) {
    return ButtonTheme(
      minWidth: 20,
      padding: EdgeInsets.symmetric(horizontal: 2),
      child: ListView.separated(
        shrinkWrap: true,
        padding: EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          if(index == 0) {
            return DropdownButton<String>(
              value: _paths[0]==""?"/":"nc:/",
              dropdownColor: Theme.of(context).accentColor,
              underline: Container(),
              onChanged: (value) {
                _onTap(value);
              },
              items: <DropdownMenuItem<String>>[
                DropdownMenuItem<String>(
                  value: "/",
                  child: Icon(Icons.phone_android, color: Colors.white,)
                ),
                DropdownMenuItem<String>(
                  value: "nc:/",
                  child: AvatarWidget.command(getIt.get<NextCloudManager>().updateAvatarCommand, radius: 12,)
                )
              ],
            );
          }
          return  FlatButton(
            textColor: Colors.white,
            onPressed: () => _onTap(_subPath(index)), 
            child: Text(_paths[index]),
          );
        }, 
        separatorBuilder: (context, index) => Icon(Icons.keyboard_arrow_right, color: Colors.white), 
        itemCount: _paths.length
      )
    );
  }

}