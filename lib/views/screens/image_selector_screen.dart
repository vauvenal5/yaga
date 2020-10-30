import 'package:flutter/material.dart';
import 'package:yaga/model/nc_file.dart';
import 'package:yaga/model/route_args/image_screen_arguments.dart';
import 'package:yaga/model/route_args/navigatable_screen_arguments.dart';
import 'package:yaga/services/intent_service.dart';
import 'package:yaga/services/isolateable/system_location_service.dart';
import 'package:yaga/services/shared_preferences_service.dart';
import 'package:yaga/utils/service_locator.dart';
import 'package:yaga/utils/uri_utils.dart';
import 'package:yaga/utils/yaga_router.dart';
import 'package:yaga/views/screens/directory_navigation_screen.dart';
import 'package:yaga/views/screens/home_view.dart';
import 'package:yaga/views/screens/image_screen.dart';
import 'package:yaga/views/widgets/image_views/nc_list_view.dart';
import 'package:yaga/model/general_view_config.dart';
import 'package:yaga/views/widgets/image_views/utils/view_configuration.dart';

class ImageSelectorScreen extends StatefulWidget {
  static const String route = "imageSelector://";

  @override
  _ImageSelectorScreenState createState() => _ImageSelectorScreenState();
}

class _ImageSelectorScreenState extends State<ImageSelectorScreen> {
  Uri uri;
  final _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    //bassically constructing the home view path property here
    GeneralViewConfig config = GeneralViewConfig(
      HomeView.pref,
      getIt.get<SystemLocationService>().externalAppDirUri,
      true,
    );

    uri = getIt
        .get<SharedPreferencesService>()
        .loadPreferenceFromString(config.path)
        .value;

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    ViewConfiguration viewConfig = ViewConfiguration.browse(
      route: ImageSelectorScreen.route,
      defaultView: NcListView.viewKey,
      onFolderTap: null,
      //todo: passing this on tap does not yet work since we are overriding it in the directory navigation screen
      // this is due to compability issues between the new and old navigators
      // onFolderTap: (NcFile file) {
      //   setState(() {
      //     uri = file.uri;
      //   });
      // },
      onFileTap: (List<NcFile> files, int index) => Navigator.pushNamed(
        context,
        ImageScreen.route,
        arguments: ImageScreenArguments(
          files,
          index,
          mainActionBuilder: (context, image) => IconButton(
            icon: Icon(Icons.check),
            onPressed: () async {
              await getIt.get<IntentService>().setSelectedFile(image);
            },
          ),
        ),
      ),
    );

    //todo: when refactoring all navigation, we should move this Navigator into the DirectoryNavigationScreen
    return WillPopScope(
      onWillPop: () async =>
          !await _navigatorKey.currentState.maybePop(context),
      child: Navigator(
        key: _navigatorKey,
        pages: _pushViews(context, viewConfig, uri),
        onGenerateRoute: YagaRouter.generateRoute,
        onPopPage: (route, result) {
          if (!route.didPop(result)) {
            return false;
          }

          setState(() {
            //todo: solve this better
            uri =
                UriUtils.fromUriPathSegments(uri, uri.pathSegments.length - 3);
          });

          return true;
        },
      ),
    );
  }

  List<MaterialPage> _pushViews(
      BuildContext context, ViewConfiguration viewConfig, Uri uri) {
    List<MaterialPage> pages = [];

    //todo: find out why passing arguments leads to strange behavior
    pages.add(_getPage(UriUtils.getRootFromUri(uri), viewConfig));

    int index = 0;
    uri.pathSegments.where((element) => element.isNotEmpty).forEach((segment) {
      pages.add(
          _getPage(UriUtils.fromUriPathSegments(uri, index++), viewConfig));
    });

    return pages;
  }

  MaterialPage _getPage(Uri uri, ViewConfiguration viewConfig) {
    return MaterialPage(
      key: ValueKey(uri.toString()),
      arguments: NavigatableScreenArguments(uri: uri),
      name: uri.toString(),
      child: DirectoryNavigationScreen(
        uri: uri,
        bottomBarBuilder: null,
        viewConfig: viewConfig,
        title: "Select image...",
        fixedOrigin: false,
      ),
    );
  }
}
