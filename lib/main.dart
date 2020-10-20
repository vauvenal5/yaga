import 'package:flutter/material.dart';
import 'package:yaga/managers/global_settings_manager.dart';
import 'package:yaga/managers/settings_manager.dart';
import 'package:yaga/model/preference.dart';
import 'package:yaga/services/shared_preferences_service.dart';
import 'package:yaga/utils/service_locator.dart';
import 'package:yaga/utils/yaga_router.dart';
import 'package:yaga/views/screens/splash_screen.dart';
import 'package:yaga/views/screens/yaga_home_screen.dart';

void main() {
  setupServiceLocator();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    ThemeData dark = ThemeData(
      brightness: Brightness.dark,
      accentColor: Colors.blue,
      toggleableActiveColor: Colors.blue,
    );

    ThemeData light = ThemeData(
      brightness: Brightness.light,
      accentColor: Colors.blue,
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
              .loadChoicePreference(GlobalSettingsManager.theme),
          stream: settingsManager.updateSettingCommand
              .where((event) => event.key == GlobalSettingsManager.theme.key)
              .where((event) => event is ChoicePreference)
              .map((event) => event as ChoicePreference),
          builder: (context, snapshot) {
            if (snapshot.data.value == "system") {
              return MaterialApp(
                title: title,
                theme: light,
                darkTheme: dark,
                initialRoute: YagaHomeScreen.route,
                onGenerateRoute: YagaRouter.generateRoute,
              );
            }

            return MaterialApp(
              title: title,
              theme: snapshot.data.value == "light" ? light : dark,
              initialRoute: YagaHomeScreen.route,
              onGenerateRoute: YagaRouter.generateRoute,
            );
          },
        );
      },
    );
  }
}
