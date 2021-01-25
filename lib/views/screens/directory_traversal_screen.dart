import 'package:flutter/material.dart';
import 'package:yaga/model/nc_file.dart';
import 'package:yaga/model/route_args/directory_navigation_screen_arguments.dart';
import 'package:yaga/utils/uri_utils.dart';
import 'package:yaga/utils/navigation/yaga_router.dart';
import 'package:yaga/views/screens/directory_screen.dart';
import 'package:yaga/views/widgets/image_views/utils/view_configuration.dart';

enum DirectoryTraversalScreenNavActions { cancel }

class DirectoryTraversalScreen extends StatefulWidget {
  final DirectoryNavigationScreenArguments args;

  DirectoryTraversalScreen(this.args);

  @override
  _DirectoryTraversalScreenState createState() =>
      _DirectoryTraversalScreenState();
}

class _DirectoryTraversalScreenState extends State<DirectoryTraversalScreen> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  Uri uri;
  ViewConfiguration viewConfig;

  @override
  void initState() {
    viewConfig = ViewConfiguration.fromViewConfig(
      viewConfig: widget.args.viewConfig,
      onFolderTap: (NcFile file) => _navigate(file.uri),
    );
    uri = widget.args.uri;
    super.initState();
  }

  void _navigate(Uri target) {
    //this is so we can find out which use case sets null
    assert(target != null, "Target is null!");
    setState(() {
      uri = target == null ? null : UriUtils.fromUri(uri: target);
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async =>
          !await _navigatorKey.currentState.maybePop(context),
      child: Navigator(
        key: _navigatorKey,
        reportsRouteUpdateToEngine: true,
        pages: _buildPages(context, viewConfig, uri),
        onGenerateRoute: YagaRouter.generateRoute,
        onPopPage: (route, result) {
          if (!route.didPop(result)) {
            return false;
          }

          return _handlePagePop(context, result);
        },
      ),
    );
  }

  bool _handlePagePop(BuildContext context, dynamic result) {
    if (result is Uri) {
      _navigate(result);
      return true;
    }

    //in case we are poping the root element we need to inform the parent navigatort
    if (result == DirectoryTraversalScreenNavActions.cancel ||
        uri == null || //todo: in which case is the uri == null?!
        uri == UriUtils.getRootFromUri(uri)) {
      Navigator.of(context).pop();
      return true;
    }

    //in case we are poping a non root element create the new page list
    setState(() {
      //todo: solve this better
      uri = UriUtils.fromUriPathSegments(
        uri,
        uri.pathSegments.length - 3,
      );
    });

    return true;
  }

  List<Page> _buildPages(
    BuildContext context,
    ViewConfiguration viewConfig,
    Uri uri,
  ) {
    List<Page> pages = [];

    pages.add(_buildPage(UriUtils.getRootFromUri(uri), viewConfig));

    int index = 0;
    uri.pathSegments.where((element) => element.isNotEmpty).forEach((segment) {
      pages.add(
        _buildPage(UriUtils.fromUriPathSegments(uri, index++), viewConfig),
      );
    });

    return pages;
  }

  Page _buildPage(Uri uri, ViewConfiguration viewConfig) {
    return MaterialPage(
      key: ValueKey(uri.toString()),
      child: DirectoryScreen(
        uri: uri,
        bottomBarBuilder: widget.args.bottomBarBuilder,
        viewConfig: viewConfig,
        title: widget.args.title,
        fixedOrigin: widget.args.fixedOrigin,
        leading: widget.args.leadingBackArrow,
      ),
    );
  }
}
