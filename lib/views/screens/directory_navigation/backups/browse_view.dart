import 'package:flutter/material.dart';
import 'package:yaga/managers/navigation_manager.dart';
import 'package:yaga/managers/nextcloud_manager.dart';
import 'package:yaga/managers/tab_manager.dart';
import 'package:yaga/model/nc_file.dart';
import 'package:yaga/model/route_args/directory_navigation_screen_arguments.dart';
import 'package:yaga/model/route_args/image_screen_arguments.dart';
import 'package:yaga/services/isolateable/nextcloud_service.dart';
import 'package:yaga/services/isolateable/system_location_service.dart';
import 'package:yaga/utils/service_locator.dart';
import 'package:yaga/utils/uri_utils.dart';
import 'package:yaga/utils/navigation/yaga_router.dart';
import 'package:yaga/views/screens/directory_navigation/backups/browse_main.dart';
import 'package:yaga/utils/navigation/yaga_route_information_parser.dart';
import 'package:yaga/views/screens/directory_navigation/backups/directory_navigation.dart';
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

class BrowseView extends StatefulWidget {
  final String _pref = "browse_tab";
  ViewConfiguration viewConfig;

  BrowseView() {
    this.viewConfig = ViewConfiguration.browse(
      route: _pref,
      defaultView: NcListView.viewKey,
      onFolderTap: null,
      onFileTap: null,
    );
  }

  @override
  _BrowseViewState createState() => _BrowseViewState();
}

class _BrowseViewState extends State<BrowseView> {
  Uri uri;

  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    getIt.get<TabManager>().tabChangedCommand.listen((value) {
      _navigate(null);
    });

    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Defer back button dispatching to the child router
    // _backButtonDispatcher = Router.of(context)
    //     .backButtonDispatcher
    //     .createChildBackButtonDispatcher();
  }

  @override
  Widget build(BuildContext context) {
    // Claim priority, If there are parallel sub router, you will need
    // to pick which one should take priority;
    // if (_backButtonDispatcher != null) {
    //   _backButtonDispatcher.takePriority();
    // }

    // return DirectoryNavigator(
    //     null,
    //     "Browse",
    //     (context, uri) => YagaBottomNavBar(YagaHomeTab.folder),
    //     widget.viewConfig);

    // return Router(
    //   routerDelegate: _routerDelegate,
    //   routeInformationParser: _informationParser,
    //   backButtonDispatcher: _backButtonDispatcher,
    // );

    // return Stack(
    //   children: [
    //     BrowseMain(_navigate),
    //     if (uri != null) DirectoryNavigation(_getArgs())
    //   ],
    // );

    DirectoryNavigationScreenArguments args = _getArgs(uri);

    return WillPopScope(
      onWillPop: () async => !await navigatorKey.currentState.maybePop(context),
      child: Navigator(
        key: navigatorKey,
        pages: [
          MaterialPage(key: ValueKey("testMain"), child: BrowseMain(_navigate)),
          if (uri != null)
            // DirectoryNavigationScreen(
            //   bottomBarBuilder: args.bottomBarBuilder,
            //   title: args.title,
            //   uri: args.uri,
            //   viewConfig: args.viewConfig,
            // )
            MaterialPage(
              key: ValueKey("test"),
              child: DirectoryTraversalScreen(_getArgs(uri)),
            )
        ],
        onPopPage: (route, result) {
          if (!route.didPop(result)) {
            return false;
          }

          _navigate(null);

          return true;
        },
      ),
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

  DirectoryNavigationScreenArguments _getArgs(Uri uri) {
    return DirectoryNavigationScreenArguments(
      uri: uri,
      title: "Browse",
      viewConfig: widget.viewConfig,
      bottomBarBuilder: (context, uri) => YagaBottomNavBar(YagaHomeTab.folder),
    );
  }

  void _navigate(Uri path) {
    if (path == null) {
      getIt.get<NavigationManager>().showDirectoryNavigation(null);
      return;
    }
    getIt.get<NavigationManager>().showDirectoryNavigation(_getArgs(path));
    // setState(() {
    //   uri = path == null ? null : UriUtils.fromUri(uri: path);
    // });
  }
}
