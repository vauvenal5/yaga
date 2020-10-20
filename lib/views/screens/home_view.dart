import 'package:yaga/model/category_view_config.dart';
import 'package:yaga/services/isolateable/system_location_service.dart';
import 'package:yaga/utils/service_locator.dart';
import 'package:yaga/views/screens/yaga_home_screen.dart';
import 'package:yaga/views/widgets/category_tab.dart';

class HomeView extends CategoryTab {
  HomeView()
      : super(CategoryViewConfig(
            defaultPath: getIt.get<SystemLocationService>().externalAppDirUri,
            pref: "category",
            pathEnabled: true,
            hasDrawer: true,
            selectedTab: YagaHomeTab.grid));
}
