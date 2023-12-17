
import 'package:catcher_2/catcher_2.dart';
import 'package:flutter/material.dart';
import 'package:yaga/managers/global_settings_manager.dart';
import 'package:yaga/managers/settings_manager.dart';
import 'package:yaga/model/preferences/choice_preference.dart';
import 'package:yaga/services/shared_preferences_service.dart';
import 'package:yaga/utils/logger.dart';
import 'package:yaga/utils/navigation/yaga_router_delegate.dart';
import 'package:yaga/utils/nextcloud_colors.dart';
import 'package:yaga/utils/service_locator.dart';
import 'package:yaga/utils/navigation/yaga_route_information_parser.dart';
import 'package:yaga/views/screens/splash_screen.dart';

Future<void> main() async {
  await YagaLogger.init();

  setupServiceLocator();

  final Catcher2Options releaseOptions = Catcher2Options(SilentReportMode(), [
    YagaLogger.fileHandler,
  ]);

  Catcher2(
    rootWidget: MyApp(),
    debugConfig: releaseOptions,
    releaseConfig: releaseOptions,
    enableLogger: false,
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final ThemeData dark = ThemeData(
      useMaterial3: false,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSwatch(
        accentColor: NextcloudColors.lightBlue,
        brightness: Brightness.dark,
      ),
    );

    final ThemeData light = ThemeData(
      useMaterial3: false,
      // brightness: Brightness.light,
      colorScheme: ColorScheme.fromSwatch(
        accentColor: NextcloudColors.lightBlue,
        brightness: Brightness.light,
      ),
    );

    const String title = "Nextcloud Yaga";

    return FutureBuilder(
      future: YagaLogger.printBaseLog().then(
        (_) => getIt.allReady(),
      ),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return MaterialApp(
            title: title,
            theme: light,
            darkTheme: dark,
            home: SplashScreen(),
          );
        }

        final settingsManager = getIt.get<SettingsManager>();

        return StreamBuilder<ChoicePreference>(
          initialData: getIt
              .get<SharedPreferencesService>()
              .loadPreferenceFromString(GlobalSettingsManager.theme),
          stream: settingsManager.updateSettingCommand
              .where((event) => event.key == GlobalSettingsManager.theme.key)
              .where((event) => event is ChoicePreference)
              .map((event) => event as ChoicePreference),
          builder: (context, snapshot) {
            if (snapshot.data!.value == "system") {
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
              theme: snapshot.data!.value == "light" ? light : dark,
              routeInformationParser: YagaRouteInformationParser(),
              routerDelegate: YagaRouterDelegate(),
            );
          },
        );
      },
    );
  }
}
