import 'package:yaga/model/category_view_config.dart';
import 'package:yaga/services/isolateable/system_location_service.dart';
import 'package:yaga/services/intent_service.dart';
import 'package:yaga/utils/service_locator.dart';
import 'package:yaga/views/screens/yaga_home_screen.dart';
import 'package:yaga/views/screens/category_view_screen.dart';

class HomeView extends CategoryViewScreen {
  static const String pref = "category";

  HomeView()
      : super(
          CategoryViewConfig(
              defaultPath:
                  getIt.get<SystemLocationService>().internalStorage.uri,
              pref: pref,
              pathEnabled: true,
              hasDrawer: true,
              selectedTab: YagaHomeTab.grid,
              title: _getTitle()),
        );

  //todo: unify this
  static String _getTitle() {
    if (getIt.get<IntentService>().isOpenForSelect) {
      return "Selecte image...";
    }

    return "Nextcloud Yaga";
  }
}
