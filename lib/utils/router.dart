import 'package:flutter/material.dart';
import 'package:yaga/utils/path_selector_screen_arguments.dart';
import 'package:yaga/views/screens/image_screen.dart';
import 'package:yaga/views/screens/nc_address_screen.dart';
import 'package:yaga/views/screens/nc_login_screen.dart';
import 'package:yaga/views/screens/path_selector_screen.dart';
import 'package:yaga/views/screens/settings_screen.dart';
import 'package:yaga/views/screens/yaga_home_screen.dart';

class Router {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch(settings.name) {
      case SettingsScreen.route:
        return MaterialPageRoute(settings: settings, builder: (context) => SettingsScreen(settings.arguments??[]));
      case PathSelectorScreen.route:
        PathSelectorScreenArguments pathSelectorScreenArguments = settings.arguments as PathSelectorScreenArguments;
        return MaterialPageRoute(
          settings: settings, 
          builder: (context) => PathSelectorScreen(
            pathSelectorScreenArguments.uri,
            pathSelectorScreenArguments.onCancel,
            pathSelectorScreenArguments.onSelect
          ));
      case NextCloudAddressScreen.route:
        return MaterialPageRoute(settings: settings, builder: (context) => NextCloudAddressScreen());
      case NextCloudLoginScreen.route:
        return MaterialPageRoute(settings: settings, builder: (context) => NextCloudLoginScreen(settings.arguments));
      case ImageScreen.route:
        return MaterialPageRoute(settings: settings, builder: (context) => ImageScreen(settings.arguments));
      default:
        return MaterialPageRoute(settings: settings, builder: (context) => YagaHomeScreen(settings.arguments??YagaHomeViews.grid));
    }
  } 
}