import 'package:flutter/material.dart';
import 'package:yaga/managers/nextcloud_manager.dart';
import 'package:yaga/model/nc_file.dart';
import 'package:yaga/model/route_args/directory_navigation_screen_arguments.dart';
import 'package:yaga/model/route_args/image_screen_arguments.dart';
import 'package:yaga/services/isolateable/nextcloud_service.dart';
import 'package:yaga/services/isolateable/system_location_service.dart';
import 'package:yaga/utils/service_locator.dart';
import 'package:yaga/utils/navigation/yaga_route_information_parser.dart';
import 'package:yaga/views/screens/directory_navigation/backups/directory_navigation_router_delegate.dart';
import 'package:yaga/views/screens/directory_traversal_page.dart';
import 'package:yaga/views/screens/directory_traversal_screen.dart';
import 'package:yaga/views/screens/image_screen.dart';
import 'package:yaga/views/screens/yaga_home_screen.dart';
import 'package:yaga/views/widgets/avatar_widget.dart';
import 'package:yaga/views/widgets/image_views/nc_list_view.dart';
import 'package:yaga/views/widgets/image_views/utils/view_configuration.dart';
import 'package:yaga/views/widgets/yaga_bottom_nav_bar.dart';
import 'package:yaga/views/widgets/yaga_drawer.dart';

class DirectoryNavigation extends StatefulWidget {
  final String _pref = "browse_tab";
  // ViewConfiguration viewConfig;
  final DirectoryNavigationScreenArguments args;

  DirectoryNavigation(this.args) {
    // this.viewConfig = ViewConfiguration.browse(
    //   route: _pref,
    //   defaultView: NcListView.viewKey,
    //   onFolderTap: null,
    //   onFileTap: null,
    // );
  }

  @override
  _DirectoryNavigationState createState() => _DirectoryNavigationState();
}

class _DirectoryNavigationState extends State<DirectoryNavigation> {
  DirectoryNavigationRouterDelegate _routerDelegate;
  // BackButtonDispatcher _backButtonDispatcher = RootBackButtonDispatcher();
  BackButtonDispatcher _backButtonDispatcher;
  YagaRouteInformationParser _informationParser = YagaRouteInformationParser();

  @override
  void initState() {
    _routerDelegate = DirectoryNavigationRouterDelegate(widget.args);
    // _routerDelegate = DirectoryNavigationRouterDelegate(
    //   widget.uri,
    //   widget.viewConfig,
    //   "Browse",
    //   (context, uri) => YagaBottomNavBar(YagaHomeTab.folder),
    // );
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Defer back button dispatching to the child router
    _backButtonDispatcher = Router.of(context)
        .backButtonDispatcher
        .createChildBackButtonDispatcher();
  }

  @override
  Widget build(BuildContext context) {
    // Claim priority, If there are parallel sub router, you will need
    // to pick which one should take priority;
    // if (_backButtonDispatcher != null) {
    _backButtonDispatcher.takePriority();
    // }

    // return DirectoryNavigator(widget.args);

    return Router(
      routerDelegate: _routerDelegate,
      routeInformationParser: _informationParser,
      backButtonDispatcher: _backButtonDispatcher,
    );

    // return Scaffold(
    //   appBar: AppBar(
    //     // Here we take the value from the MyHomePage object that was created by
    //     // the App.build method, and use it to set our appbar title.
    //     title: Text("Nextcloud Yaga"),
    //   ),
    //   drawer: YagaDrawer(),
    //   body: Router(routerDelegate: _routerDelegate),
    //   bottomNavigationBar: YagaBottomNavBar(YagaHomeTab.folder),
    // );
  }
}
