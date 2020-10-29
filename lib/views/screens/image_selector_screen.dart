import 'package:flutter/material.dart';
import 'package:yaga/model/nc_file.dart';
import 'package:yaga/model/route_args/image_screen_arguments.dart';
import 'package:yaga/services/intent_service.dart';
import 'package:yaga/services/isolateable/nextcloud_service.dart';
import 'package:yaga/utils/service_locator.dart';
import 'package:yaga/views/screens/directory_navigation_screen.dart';
import 'package:yaga/views/screens/image_screen.dart';
import 'package:yaga/views/widgets/image_views/nc_list_view.dart';
import 'package:yaga/views/widgets/image_views/utils/view_configuration.dart';

class ImageSelectorScreen extends StatelessWidget {
  static const String route = "imageSelector://";

  @override
  Widget build(BuildContext context) {
    ViewConfiguration viewConfig = ViewConfiguration.browse(
      route: route,
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

    return DirectoryNavigationScreen(
      uri: getIt.get<NextCloudService>().getOrigin(),
      bottomBarBuilder: null,
      viewConfig: viewConfig,
      title: "Select image...",
      fixedOrigin: false,
    );
  }
}
