import 'package:flutter/material.dart';

class PathWidget extends StatelessWidget {
  final List<String> _paths;
  final Function _onTap;

  PathWidget(String path, this._onTap) : _paths = path.split("/");

  String _subPath(int index) {
    String subPath = "";
    for(int i = 1; i<=index;i++) {
      subPath += "/"+_paths[i];
    }
    return subPath;
  }

  @override
  Widget build(BuildContext context) {
    return ButtonTheme(
      minWidth: 10,
      padding: EdgeInsets.symmetric(horizontal: 2),
      child: ListView.separated(
        shrinkWrap: true,
        padding: EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          if(index == 0) {
            return InkWell(
              onTap: () => _onTap("/"),
              child: Icon(Icons.phone_android, color: Colors.white,)
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