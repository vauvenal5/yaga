import 'package:flutter/material.dart';
import 'package:yaga/utils/path_selector_screen_arguments.dart';
import 'package:yaga/views/screens/path_selector_screen.dart';
import 'package:yaga/views/screens/settings_screen.dart';
import 'package:yaga/views/screens/yaga_home_screen.dart';

class Router {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch(settings.name) {
      case SettingsScreen.route:
        return MaterialPageRoute(settings: settings, builder: (context) => SettingsScreen(settings.arguments??[]));
      case PathSelectorScreen.route:
        PathSelectorScreenArguments pathSelectorScreenArguments = settings.arguments as PathSelectorScreenArguments ?? PathSelectorScreenArguments.empty();
        return MaterialPageRoute(
          settings: settings, 
          builder: (context) => PathSelectorScreen(
            pathSelectorScreenArguments.path,
            pathSelectorScreenArguments.onCancel,
            pathSelectorScreenArguments.onSelect
          ));
      default:
        return MaterialPageRoute(settings: settings, builder: (context) => YagaHomeScreen());
    }
  } 
}