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
  final bool fixedOrigin;

  PathWidget(this._uri, this._onTap, {this.fixedOrigin = false});

  @override
  Widget build(BuildContext context) {
    return ButtonTheme(
      minWidth: 20,
      padding: EdgeInsets.symmetric(horizontal: 2),
      child: ListView.separated(
        shrinkWrap: true,
        padding: EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: _uri.pathSegments.length == 0 ? 1 : _uri.pathSegments.length,
        itemBuilder: (context, index) {
          if (index == 0) {
            String selected = UriUtils.getRootFromUri(_uri).toString();

            if (fixedOrigin) {
              return _getDisabledAvatar(selected);
            }

            List<DropdownMenuItem<String>> items = [];

            items.add(_getMenuItem(
              getIt.get<SystemLocationService>().getOrigin().toString(),
            ));

            if (getIt.get<NextCloudService>().isLoggedIn()) {
              items.add(
                _getMenuItem(
                  getIt
                      .get<NextCloudService>()
                      .origin
                      .userEncodedDomainRoot
                      .toString(),
                ),
              );
            }

            getIt.get<SystemLocationService>().externals.forEach((element) {
              items.add(_getMenuItem(
                getIt
                    .get<SystemLocationService>()
                    .getOrigin(host: element)
                    .toString(),
              ));
            });

            return DropdownButtonHideUnderline(
              child: DropdownButton(
                value: selected,
                onChanged: (value) => _onTap(Uri.parse(value)),
                items: items,
              ),
            );
          }
          Uri subUri = UriUtils.fromUriPathSegments(_uri, index - 1);
          return FlatButton(
            textColor: Colors.white,
            onPressed: () => _onTap(subUri),
            child: Text(UriUtils.getNameFromUri(subUri)),
          );
        },
        separatorBuilder: (context, index) =>
            Icon(Icons.keyboard_arrow_right, color: Colors.white),
      ),
    );
  }

  DropdownMenuItem<String> _getMenuItem(String origin) {
    return DropdownMenuItem<String>(
      value: origin,
      child: _getAvatarForOrigin(origin),
    );
  }

  Widget _getDisabledAvatar(String origin) {
    return InkWell(
      onTap: () => _onTap(Uri.parse(origin)),
      child: _getAvatarForOrigin(origin),
    );
  }

  Widget _getAvatarForOrigin(String origin) {
    if (getIt.get<SystemLocationService>().getOrigin().toString() == origin) {
      return AvatarWidget.phone();
    }

    if (origin.startsWith(getIt.get<NextCloudService>().scheme)) {
      return AvatarWidget.command(
        getIt.get<NextCloudManager>().updateAvatarCommand,
      );
    }

    return AvatarWidget.sd();
  }
}
