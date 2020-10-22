import 'package:flutter/material.dart';
import 'package:yaga/managers/nextcloud_manager.dart';
import 'package:yaga/services/isolateable/nextcloud_service.dart';
import 'package:yaga/services/isolateable/system_location_service.dart';
import 'package:yaga/utils/service_locator.dart';
import 'package:yaga/utils/uri_utils.dart';
import 'package:yaga/views/widgets/avatar_widget.dart';

class PathWidget extends StatelessWidget {
  final Uri _uri;
  final Function(Uri) _onTap;

  PathWidget(this._uri, this._onTap);

  @override
  Widget build(BuildContext context) {
    return ButtonTheme(
        minWidth: 20,
        padding: EdgeInsets.symmetric(horizontal: 2),
        child: ListView.separated(
          shrinkWrap: true,
          padding: EdgeInsets.symmetric(horizontal: 20),
          scrollDirection: Axis.horizontal,
          itemCount:
              _uri.pathSegments.length == 0 ? 1 : _uri.pathSegments.length,
          itemBuilder: (context, index) {
            if (index == 0) {
              List<DropdownMenuItem<String>> items = [
                DropdownMenuItem<String>(
                  value:
                      getIt.get<SystemLocationService>().getOrigin().toString(),
                  child: AvatarWidget.phone(),
                ),
              ];

              if (getIt.get<NextCloudService>().isLoggedIn()) {
                items.add(
                  DropdownMenuItem<String>(
                    value: getIt.get<NextCloudService>().getOrigin().toString(),
                    child: AvatarWidget.command(
                      getIt.get<NextCloudManager>().updateAvatarCommand,
                    ),
                  ),
                );
              }

              return DropdownButtonHideUnderline(
                child: DropdownButton(
                  value: UriUtils.getRootFromUri(_uri).toString(),
                  onChanged: (value) {
                    _onTap(Uri.parse(value));
                  },
                  items: items,
                ),
              );
            }
            return FlatButton(
              textColor: Colors.white,
              onPressed: () =>
                  _onTap(UriUtils.fromUriPathSegments(_uri, index - 1)),
              child: Text(_uri.pathSegments[index - 1]),
            );
          },
          separatorBuilder: (context, index) =>
              Icon(Icons.keyboard_arrow_right, color: Colors.white),
        ));
  }
}
