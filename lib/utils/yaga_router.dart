import 'package:flutter/material.dart';
import 'package:yaga/model/route_args/choice_selector_screen_arguments.dart';
import 'package:yaga/model/route_args/directory_navigation_screen_arguments.dart';
import 'package:yaga/model/route_args/focus_view_arguments.dart';
import 'package:yaga/model/route_args/image_screen_arguments.dart';
import 'package:yaga/model/route_args/path_selector_screen_arguments.dart';
import 'package:yaga/model/route_args/settings_screen_arguments.dart';
import 'package:yaga/utils/logger.dart';
import 'package:yaga/views/screens/choice_selector_screen.dart';
import 'package:yaga/views/screens/directory_navigation_screen.dart';
import 'package:yaga/views/screens/focus_view.dart';
import 'package:yaga/views/screens/image_screen.dart';
import 'package:yaga/views/screens/image_selector_screen.dart';
import 'package:yaga/views/screens/nc_address_screen.dart';
import 'package:yaga/views/screens/nc_login_screen.dart';
import 'package:yaga/views/screens/path_selector_screen.dart';
import 'package:yaga/views/screens/settings_screen.dart';
import 'package:yaga/views/screens/yaga_home_screen.dart';
import 'package:logger/logger.dart';

class YagaRouter {
  static Logger _logger = getLogger(YagaRouter);

  static String getInitialRoute(String intentAction) {
    _logger.i("Setting main view based on intent-action: $intentAction");

    //todo: find plugin with defined constants
    if (intentAction == "android.intent.action.GET_CONTENT") {
      return ImageSelectorScreen.route;
    }

    return YagaHomeScreen.route;
  }

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case SettingsScreen.route:
        SettingsScreenArguments args =
            settings.arguments as SettingsScreenArguments;
        return MaterialPageRoute(
            settings: settings,
            builder: (context) => SettingsScreen(
                  args.preferences,
                  onCancel: args.onCancel,
                  onCommit: args.onCommit,
                  onPreferenceChangedCommand: args.onSettingChangedCommand,
                ));
      case PathSelectorScreen.route:
        PathSelectorScreenArguments pathSelectorScreenArguments =
            settings.arguments as PathSelectorScreenArguments;
        return MaterialPageRoute(
            settings: settings,
            builder: (context) => PathSelectorScreen(
                  pathSelectorScreenArguments.uri,
                  pathSelectorScreenArguments.onCancel,
                  pathSelectorScreenArguments.onSelect,
                  onFileTap: pathSelectorScreenArguments.onFileTap,
                  title: pathSelectorScreenArguments.title,
                  fixedOrigin: pathSelectorScreenArguments.fixedOrigin,
                ));
      case DirectoryNavigationScreen.route:
        DirectoryNavigationScreenArguments args =
            settings.arguments as DirectoryNavigationScreenArguments;
        return MaterialPageRoute(
            settings: settings,
            builder: (context) => DirectoryNavigationScreen(
                  uri: args.uri,
                  title: args.title,
                  bottomBarBuilder: args.bottomBarBuilder,
                  viewConfig: args.viewConfig,
                ));
      case NextCloudAddressScreen.route:
        return MaterialPageRoute(
            settings: settings, builder: (context) => NextCloudAddressScreen());
      case NextCloudLoginScreen.route:
        return MaterialPageRoute(
            settings: settings,
            builder: (context) => NextCloudLoginScreen(settings.arguments));
      case ImageScreen.route:
        ImageScreenArguments args = settings.arguments as ImageScreenArguments;
        return MaterialPageRoute(
            settings: settings,
            builder: (context) => ImageScreen(
                  args.images,
                  args.index,
                  title: args.title,
                  mainActionBuilder: args.mainActionBuilder,
                ));
      case ChoiceSelectorScreen.route:
        ChoiceSelectorScreenArguments args =
            settings.arguments as ChoiceSelectorScreenArguments;
        return MaterialPageRoute(
            settings: settings,
            builder: (context) => ChoiceSelectorScreen(
                args.choicePreference, args.onSelect, args.onCancel));
      case FocusView.route:
        FocusViewArguments args = settings.arguments as FocusViewArguments;
        return MaterialPageRoute(
            settings: settings, builder: (context) => FocusView(args.path));
      case ImageSelectorScreen.route:
        return MaterialPageRoute(
          settings: settings,
          builder: (context) => ImageSelectorScreen(),
        );
      default:
        return MaterialPageRoute(
          settings: settings,
          builder: (context) => YagaHomeScreen(),
        );
    }
  }
}
