import 'package:yaga/model/category_view_config.dart';
import 'package:yaga/views/screens/yaga_home_screen.dart';
import 'package:yaga/views/widgets/category_tab.dart';

class FocusView extends CategoryTab {
  static const String route = "/focus";

  FocusView(Uri path)
      : super(CategoryViewConfig(
            defaultPath: path,
            pref: "focus",
            pathEnabled: false,
            hasDrawer: false,
            selectedTab: YagaHomeTab.folder));
}
