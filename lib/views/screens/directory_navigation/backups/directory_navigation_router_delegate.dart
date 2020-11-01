import 'dart:io';

import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:yaga/managers/navigation_manager.dart';
import 'package:yaga/model/nc_file.dart';
import 'package:yaga/model/route_args/directory_navigation_screen_arguments.dart';
import 'package:yaga/utils/logger.dart';
import 'package:yaga/utils/service_locator.dart';
import 'package:yaga/utils/uri_utils.dart';
import 'package:yaga/utils/navigation/yaga_router.dart';
import 'package:yaga/views/screens/directory_navigation/backups/browse_main.dart';
import 'package:yaga/views/screens/directory_traversal_page.dart';
import 'package:yaga/views/screens/settings_screen.dart';
import 'package:yaga/views/widgets/image_views/utils/view_configuration.dart';

class DirectoryNavigationRouterDelegate extends RouterDelegate<Uri>
    with ChangeNotifier, PopNavigatorRouterDelegateMixin<Uri> {
  final Logger _logger = getLogger(DirectoryNavigationRouterDelegate);
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  // final ViewConfiguration _viewConfig;
  // final String title;
  // final Widget Function(BuildContext, Uri) _bottomBarBuilder;
  final DirectoryNavigationScreenArguments args;
  Uri uri;
  // Uri pages = Uri();

  DirectoryNavigationRouterDelegate(this.args) {
    uri = this.args.uri;
    // getIt
    //     .get<NavigationManager>()
    //     .navigate
    //     .where((event) => event.navigatorState == navigatorKey.currentState)
    //     .listen((event) {
    //   pages = UriUtils.fromPathSegments(
    //       uri: pages,
    //       pathSegments: []
    //         ..addAll(pages.pathSegments)
    //         ..add(event.relativeRoute));
    //   notifyListeners();
    // });
  }

  @override
  Widget build(BuildContext context) {
    ViewConfiguration viewConfig = ViewConfiguration.fromViewConfig(
        viewConfig: this.args.viewConfig,
        onFolderTap: (NcFile file) => _navigate(file.uri));

    return
        // WillPopScope(
        //   onWillPop: () async => !await navigatorKey.currentState.maybePop(context),
        //   child:
        Navigator(
      key: navigatorKey,
      pages: _buildPages(context, viewConfig, uri),
      // onGenerateRoute: YagaRouter.generateRoute,
      onPopPage: (route, result) {
        if (!route.didPop(result)) {
          return false;
        }

        if (result is Uri) {
          _navigate(result);
          return true;
        }

        if (uri == null || uri == UriUtils.getRootFromUri(uri)) {
          // _navigate(null);
          return true;
        }

        //todo: solve this better
        _navigate(UriUtils.fromUriPathSegments(
          uri,
          uri.pathSegments.length - 3,
        ));

        return true;
      },
      // ),
    );
  }

  @override
  Future<void> setNewRoutePath(Uri configuration) {
    assert(false);
  }

  List<Page> _buildPages(
    BuildContext context,
    ViewConfiguration viewConfig,
    Uri uri,
  ) {
    List<Page> pages = [];
    _logger.w("Building pages");

    // pages.add(_buildMain(viewConfig));

    if (uri == null) {
      throw UnsupportedError("Overseen null!");
    }

    pages.add(_buildPage(context, UriUtils.getRootFromUri(uri), viewConfig));

    int index = 0;
    uri.pathSegments.where((element) => element.isNotEmpty).forEach((segment) {
      Uri subUri = UriUtils.fromUriPathSegments(uri, index++);
      pages.add(_buildPage(context, subUri, viewConfig));
    });

    // this.pages?.pathSegments?.forEach((segment) {
    //   if (segment == SettingsScreen.route) {
    //     pages.add(
    //       MaterialPage(
    //         key: ValueKey(segment),
    //         child: SettingsScreen([
    //           _viewConfig.section,
    //           _viewConfig.view,
    //         ]),
    //       ),
    //     );
    //   }
    // });

    return pages;
  }

  // MaterialPage _buildMain(ViewConfiguration viewConfig) {
  //   return MaterialPage(
  //     key: ValueKey("/browse"),
  //     child: BrowseMain(this._navigate, viewConfig),
  //   );
  // }

  Page _buildPage(BuildContext context, Uri uri, ViewConfiguration viewConfig) {
    return
        // MaterialPage(
        //   key: ValueKey(uri.toString()),
        //   // arguments: NavigatableScreenArguments(uri: uri),
        //   name: uri.toString(),
        //   child:
        DirectoryTraversalPage(
      uri: uri,
      bottomBarBuilder: this.args.bottomBarBuilder,
      // navigate: (Uri path) => navigatorKey.currentState.pop(path),
      //todo: report bug -> this makes everything go boom thanks to the open dropdown menu
      // navigate: (Uri path) => _navigate(path),
      viewConfig: viewConfig,
      title: this.args.title,
      fixedOrigin: false,
      // ),
    );
  }

  void _navigate(Uri target) {
    uri = target == null ? null : UriUtils.fromUri(uri: target);
    notifyListeners();
  }
}
