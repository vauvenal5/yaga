import 'package:yaga/model/general_view_config.dart';
import 'package:yaga/views/screens/yaga_home_screen.dart';

class CategoryViewConfig {
  // final Uri defaultPath;
  final String pref;
  final YagaHomeTab selectedTab;
  final bool hasDrawer;
  // final bool pathEnabled;
  final String title;
  final GeneralViewConfig generalViewConfig;

  CategoryViewConfig(
      {Uri defaultPath,
      this.pref,
      this.selectedTab,
      this.hasDrawer,
      bool pathEnabled,
      this.title})
      : generalViewConfig = GeneralViewConfig(pref, defaultPath, pathEnabled);
}
