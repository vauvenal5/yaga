import 'package:yaga/views/screens/yaga_home_screen.dart';

class CategoryViewConfig {
  final Uri defaultPath;
  final String pref;
  final YagaHomeTab selectedTab;
  final bool hasDrawer;
  final bool pathEnabled;

  CategoryViewConfig(
      {this.defaultPath,
      this.pref,
      this.selectedTab,
      this.hasDrawer,
      this.pathEnabled});
}
