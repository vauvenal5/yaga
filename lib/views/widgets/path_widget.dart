import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:yaga/managers/nextcloud_manager.dart';
import 'package:yaga/services/local_image_provider_service.dart';
import 'package:yaga/services/nextcloud_service.dart';
import 'package:yaga/services/system_location_service.dart';
import 'package:yaga/utils/service_locator.dart';
import 'package:yaga/utils/uri_utils.dart';
import 'package:yaga/views/widgets/avatar_widget.dart';

class PathWidget extends StatelessWidget {
  final Uri _uri;
  final Function(Uri) _onTap;

  PathWidget(this._uri, this._onTap);

  Uri _subPath(int index) {
    String subPath = "";
    for(int i = 0; i<=index;i++) {
      subPath += "/"+this._uri.pathSegments[i];
    }
    return UriUtils.fromUri(uri: _uri, path: subPath);
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
        itemCount: _uri.pathSegments.length+1,
        itemBuilder: (context, index) {
          if(index == 0) {
            List<DropdownMenuItem<String>> items = [
              DropdownMenuItem<String>(
                  value: getIt.get<SystemLocationService>().getOrigin().toString(),
                  child: Icon(Icons.phone_android, color: Colors.white,)
                ),
            ];

            if(getIt.get<NextCloudService>().isLoggedIn()) {
              items.add(DropdownMenuItem<String>(
                value: getIt.get<NextCloudService>().getOrigin().toString(),
                child: AvatarWidget.command(getIt.get<NextCloudManager>().updateAvatarCommand, radius: 12,)
              ));
            }

            return DropdownButton<String>(
              value: Uri(scheme: _uri.scheme, userInfo: _uri.userInfo, host: _uri.host).toString(),
              dropdownColor: Theme.of(context).accentColor,
              underline: Container(),
              onChanged: (value) {
                Uri origin = Uri.parse(value);
                //todo-sv: is this path really necessary 1/2
                _onTap(Uri(scheme: origin.scheme, host: origin.host, userInfo: origin.userInfo, path: "/"));
              },
              items: items,
            );
          }
          return  FlatButton(
            textColor: Colors.white,
            onPressed: () => _onTap(_subPath(index-1)), 
            child: Text(_uri.pathSegments[index-1]),
          );
        },
        separatorBuilder: (context, index) => Icon(Icons.keyboard_arrow_right, color: Colors.white),
      )
    );
  }

}