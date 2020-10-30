import 'package:yaga/model/category_view_config.dart';
import 'package:yaga/utils/uri_utils.dart';
import 'package:yaga/views/screens/yaga_home_screen.dart';
import 'package:yaga/views/screens/category_view_screen.dart';

class FocusView extends CategoryViewScreen {
  static const String route = "/focus";

  FocusView(Uri path)
      : super(CategoryViewConfig(
            defaultPath: path,
            pref: "focus",
            pathEnabled: false,
            hasDrawer: false,
            selectedTab: YagaHomeTab.folder,
            title: UriUtils.getNameFromUri(path)));
}
