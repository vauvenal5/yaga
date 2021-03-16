import 'package:flutter/material.dart';
import 'package:yaga/managers/global_settings_manager.dart';
import 'package:yaga/managers/settings_manager.dart';
import 'package:yaga/model/preferences/choice_preference.dart';
import 'package:yaga/services/shared_preferences_service.dart';
import 'package:yaga/utils/navigation/yaga_router_delegate.dart';
import 'package:yaga/utils/nextcloud_colors.dart';
import 'package:yaga/utils/service_locator.dart';
import 'package:yaga/utils/navigation/yaga_route_information_parser.dart';
import 'package:yaga/views/screens/splash_screen.dart';

void main() {
  setupServiceLocator();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    ThemeData dark = ThemeData(
      brightness: Brightness.dark,
      accentColor: NextcloudColors.lightBlue,
      toggleableActiveColor: NextcloudColors.lightBlue,
    );

    ThemeData light = ThemeData(
      brightness: Brightness.light,
      accentColor: NextcloudColors.lightBlue,
    );

    const String title = "Nextcloud Yaga";

    return FutureBuilder(
      future: getIt.allReady(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return MaterialApp(
            title: title,
            theme: light,
            darkTheme: dark,
            home: SplashScreen(),
          );
        }

        var settingsManager = getIt.get<SettingsManager>();

        return StreamBuilder<ChoicePreference>(
          initialData: getIt
              .get<SharedPreferencesService>()
              .loadPreferenceFromString(GlobalSettingsManager.theme),
          stream: settingsManager.updateSettingCommand
              .where((event) => event.key == GlobalSettingsManager.theme.key)
              .where((event) => event is ChoicePreference)
              .map((event) => event as ChoicePreference),
          builder: (context, snapshot) {
            if (snapshot.data.value == "system") {
              return MaterialApp.router(
                title: title,
                theme: light,
                darkTheme: dark,
                routeInformationParser: YagaRouteInformationParser(),
                routerDelegate: YagaRouterDelegate(),
              );
            }

            return MaterialApp.router(
              title: title,
              theme: snapshot.data.value == "light" ? light : dark,
              routeInformationParser: YagaRouteInformationParser(),
              routerDelegate: YagaRouterDelegate(),
            );
          },
        );
      },
    );
  }
}
