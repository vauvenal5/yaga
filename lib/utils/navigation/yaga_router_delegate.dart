import 'package:flutter/material.dart';
import 'package:yaga/managers/navigation_manager.dart';
import 'package:yaga/managers/tab_manager.dart';
import 'package:yaga/model/route_args/directory_navigation_screen_arguments.dart';
import 'package:yaga/services/intent_service.dart';
import 'package:yaga/utils/service_locator.dart';
import 'package:yaga/utils/navigation/yaga_router.dart';
import 'package:yaga/views/screens/directory_traversal_screen.dart';
import 'package:yaga/views/screens/yaga_home_screen.dart';

class YagaRouterDelegate extends RouterDelegate<Uri>
    with ChangeNotifier, PopNavigatorRouterDelegateMixin<Uri> {
  @override
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  final NavigationManager _navigationManager = getIt.get<NavigationManager>();
  IntentService intentService = getIt.get<IntentService>();

  YagaRouterDelegate() {
    _navigationManager.showDirectoryNavigation.listen((value) {
      notifyListeners();
    });

    getIt
        .get<TabManager>()
        .tabChangedCommand
        .listen((value) => _navigationManager.showDirectoryNavigation(null));
  }

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: navigatorKey,
      onGenerateRoute: generateRoute,
      pages: [getInitialPage(), ..._buildDirectoryNavigationPage()],
      onPopPage: (route, result) {
        if (!route.didPop(result)) {
          return false;
        }

        _navigationManager.showDirectoryNavigation(null);

        return true;
      },
    );
  }

  @override
  Future<void> setNewRoutePath(Uri configuration) async {
    //todo: we are not yet handling roots from the system
  }

  List<Page> _buildDirectoryNavigationPage() {
    final DirectoryNavigationScreenArguments? args =
        _navigationManager.showDirectoryNavigation.lastResult;

    if (args == null) {
      return [];
    }

    return [
      MaterialPage(
        key: ValueKey(args.uri.toString()),
        child: DirectoryTraversalScreen(args),
      )
    ];
  }

  Page getInitialPage() {
    return MaterialPage(
      key: const ValueKey(YagaHomeScreen.route),
      child: YagaHomeScreen(),
    );
  }
}
