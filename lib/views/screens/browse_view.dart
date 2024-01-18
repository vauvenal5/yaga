import 'dart:io';

import 'package:flutter/material.dart';
import 'package:yaga/managers/navigation_manager.dart';
import 'package:yaga/managers/nextcloud_manager.dart';
import 'package:yaga/model/nc_file.dart';
import 'package:yaga/model/nc_origin.dart';
import 'package:yaga/model/route_args/directory_navigation_screen_arguments.dart';
import 'package:yaga/model/route_args/image_screen_arguments.dart';
import 'package:yaga/model/system_location.dart';
import 'package:yaga/services/isolateable/nextcloud_service.dart';
import 'package:yaga/services/isolateable/system_location_service.dart';
import 'package:yaga/services/intent_service.dart';
import 'package:yaga/utils/service_locator.dart';
import 'package:yaga/views/screens/image_screen.dart';
import 'package:yaga/views/screens/yaga_home_screen.dart';
import 'package:yaga/views/widgets/avatar_widget.dart';
import 'package:yaga/views/widgets/image_views/nc_list_view.dart';
import 'package:yaga/views/widgets/image_views/utils/view_configuration.dart';
import 'package:yaga/views/widgets/yaga_bottom_nav_bar.dart';
import 'package:yaga/views/widgets/yaga_drawer.dart';

class BrowseView extends StatelessWidget {
  String get pref => "browse_tab";

  final bool favorites;

  const BrowseView({super.key, this.favorites = false});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(_getTitle() ?? "Nextcloud Yaga"),
      ),
      drawer: YagaDrawer(),
      body: StreamBuilder(
          stream: getIt.get<NextCloudManager>().updateLoginStateCommand,
          builder: (context, snapshot) {
            final List<ListTile> children = [];

            if (Platform.isAndroid && !favorites) {
              children.add(_buildLocalStorageTile(context));

              getIt.get<SystemLocationService>().externals.forEach((element) {
                children.add(_buildSDCardTile(context, element));
              });
            }

            if (getIt.get<NextCloudService>().isLoggedIn()) {
              final NcOrigin origin = getIt.get<NextCloudService>().origin!;
              children.add(_buildNextcloudTile(context, origin));
            }

            return ListView(
              children: children,
            );
          }),
      bottomNavigationBar: buildBottomNavBar(),
    );
  }

  YagaBottomNavBar buildBottomNavBar() {
    return favorites
        ? const YagaBottomNavBar(YagaHomeTab.favorites)
        : const YagaBottomNavBar(YagaHomeTab.folder);
  }

  ListTile _buildLocalStorageTile(BuildContext context) {
    return ListTile(
      // isThreeLine: false,
      leading: const AvatarWidget.phone(),
      title: const Text("Internal Memory"),
      onTap: () =>
          getIt.get<NavigationManager>().showDirectoryNavigation(_getArgs(
                context,
                getIt.get<SystemLocationService>().internalStorage.origin,
              )),
    );
  }

  ListTile _buildSDCardTile(BuildContext context, SystemLocation element) {
    return ListTile(
      // isThreeLine: false,
      leading: const AvatarWidget.sd(),
      title: Text(element.origin.userInfo),
      onTap: () => getIt.get<NavigationManager>().showDirectoryNavigation(
            _getArgs(
              context,
              element.origin,
            ),
          ),
    );
  }

  ListTile _buildNextcloudTile(BuildContext context, NcOrigin origin) {
    return ListTile(
      isThreeLine: true,
      leading: AvatarWidget.command(
        getIt.get<NextCloudManager>().updateAvatarCommand,
      ),
      title: Text(origin.displayName),
      subtitle: Text(origin.domain),
      onTap: () => getIt.get<NavigationManager>().showDirectoryNavigation(
            _getArgs(context, origin.userEncodedDomainRoot),
          ),
    );
  }

  //todo: unify this
  String? _getTitle() {
    if (getIt.get<IntentService>().isOpenForSelect) {
      return "Selecte image...";
    }

    return null;
  }

  DirectoryNavigationScreenArguments _getArgs(BuildContext context, Uri uri) {
    final ViewConfiguration viewConfig = ViewConfiguration.browse(
      route: pref,
      defaultView: NcListView.viewKey,
      favorites: favorites,
      //todo: implicit navigation
      onFileTap: (List<NcFile> files, int index) => Navigator.pushNamed(
        context,
        ImageScreen.route,
        arguments: ImageScreenArguments(files, index),
      ),
    );

    return DirectoryNavigationScreenArguments(
      uri: uri,
      title: _getTitle() ?? (favorites ? "Favorites" : "Browse"),
      fixedOrigin: favorites,
      viewConfig: viewConfig,
      //todo: this can now be probably be removed and YagaBottomNavBar can be created directly in DirectoryNavigationScreen
      bottomBarBuilder: (context, uri) => buildBottomNavBar(),
    );
  }
}
