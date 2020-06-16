import 'package:flutter/material.dart';
import 'package:yaga/managers/nextcloud_manager.dart';
import 'package:yaga/model/nc_file.dart';
import 'package:yaga/model/route_args/directory_navigation_arguments.dart';
import 'package:yaga/model/route_args/image_screen_arguments.dart';
import 'package:yaga/services/local_image_provider_service.dart';
import 'package:yaga/services/nextcloud_service.dart';
import 'package:yaga/utils/service_locator.dart';
import 'package:yaga/views/screens/directory_navigation_screen.dart';
import 'package:yaga/views/screens/image_screen.dart';
import 'package:yaga/views/widgets/avatar_widget.dart';

class BrowseTab extends StatelessWidget {

  Widget bottomNavBar;

  BrowseTab({this.bottomNavBar});

  void _navigateToBrowseView(BuildContext context, Uri origin) {
    Navigator.pushNamed(
      context, 
      DirectoryNavigationScreen.route, 
      arguments: DirectoryNavigationArguments(
        title: "Browse",
        //todo-sv: is this path really necessary 2/2
        uri: Uri(scheme: origin.scheme, userInfo: origin.userInfo, host: origin.host, path: "/"),
        onFileTap: (List<NcFile> files, int index) => Navigator.pushNamed(
          context, 
          ImageScreen.route, 
          arguments: ImageScreenArguments(files, index)
        ),
        bottomBar: bottomNavBar
      )
    );
  }

  @override
  Widget build(BuildContext context) {

    List<ListTile> children = [];

    children.add(
      ListTile(
        leading: Icon(Icons.phone_android,),
        title: Text("Internal Memory"),
        onTap: () => _navigateToBrowseView(context, getIt.get<LocalImageProviderService>().getOrigin()),
      )
    );
    
    if(getIt.get<NextCloudService>().isLoggedIn()) {
      Uri origin = getIt.get<NextCloudService>().getOrigin();
      children.add(
        ListTile(
          leading: AvatarWidget.command(getIt.get<NextCloudManager>().updateAvatarCommand, radius: 12,),
          title: Text(origin.authority),
          onTap: () => _navigateToBrowseView(context, origin),
        )
      );
    }

    return ListView(children: children,);
  }

}