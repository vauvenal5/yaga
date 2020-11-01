import 'package:flutter/material.dart';
import 'package:yaga/model/nc_file.dart';
import 'package:yaga/model/route_args/directory_navigation_screen_arguments.dart';
import 'package:yaga/model/route_args/image_screen_arguments.dart';
import 'package:yaga/services/intent_service.dart';
import 'package:yaga/services/isolateable/system_location_service.dart';
import 'package:yaga/services/shared_preferences_service.dart';
import 'package:yaga/utils/service_locator.dart';
import 'package:yaga/views/screens/directory_traversal_screen.dart';
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
    return DirectoryTraversalScreen(_getArgs(viewConfig));
  }

  DirectoryNavigationScreenArguments _getArgs(ViewConfiguration viewConfig) {
    return DirectoryNavigationScreenArguments(
      uri: this.uri,
      bottomBarBuilder: null,
      title: "Select image...",
      viewConfig: viewConfig,
      leadingBackArrow: false,
    );
  }
}
