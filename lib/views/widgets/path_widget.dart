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
  final String schemeFilter;

  PathWidget(
    this._uri,
    this._onTap, {
    this.fixedOrigin = false,
    this.schemeFilter = "",
  });

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
            Uri selected = UriUtils.getRootFromUri(_uri);

            if (fixedOrigin) {
              return _getDisabledAvatar(selected);
            }

            List<DropdownMenuItem<Uri>> items = [];
            SystemLocationService systemLocationService =
                getIt.get<SystemLocationService>();

            items.add(_getMenuItem(
              systemLocationService.internalStorage.origin,
            ));

            if (getIt.get<NextCloudService>().isLoggedIn()) {
              items.add(
                _getMenuItem(
                  getIt.get<NextCloudService>().origin.userEncodedDomainRoot,
                ),
              );
            }

            getIt.get<SystemLocationService>().externals.forEach((element) {
              items.add(_getMenuItem(
                element.origin,
              ));
            });

            if (schemeFilter.isNotEmpty) {
              items = items
                  .where((element) => element.value.scheme == schemeFilter)
                  .toList();
            }

            return DropdownButtonHideUnderline(
              child: DropdownButton(
                value: selected,
                onChanged: (value) => _onTap(value),
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

  DropdownMenuItem<Uri> _getMenuItem(Uri origin) {
    return DropdownMenuItem<Uri>(
      value: origin,
      child: _getAvatarForOrigin(origin),
    );
  }

  Widget _getDisabledAvatar(Uri origin) {
    return InkWell(
      onTap: () => _onTap(origin),
      child: _getAvatarForOrigin(origin),
    );
  }

  Widget _getAvatarForOrigin(Uri origin) {
    if (getIt.get<SystemLocationService>().internalStorage.origin == origin) {
      return AvatarWidget.phone();
    }

    if (origin.scheme == getIt.get<NextCloudService>().scheme) {
      return AvatarWidget.command(
        getIt.get<NextCloudManager>().updateAvatarCommand,
      );
    }

    return AvatarWidget.sd();
  }
}
