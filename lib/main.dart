import 'package:flutter/material.dart';
import 'package:yaga/managers/settings_manager.dart';
import 'package:yaga/model/preference.dart';
import 'package:yaga/services/shared_preferences_service.dart';
import 'package:yaga/utils/service_locator.dart';
import 'package:yaga/utils/router.dart';
import 'package:yaga/views/screens/yaga_home_screen.dart';

void main() {
  setupServiceLocator();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  static SectionPreference appSection = SectionPreference("app", "General");
  static ChoicePreference theme = ChoicePreference.section(appSection, "theme", "Theme", "system", {
    "system" : "Follow System Theme",
    "light" : "Light Theme",
    "dark" : "Dark Theme"
  });

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

    return FutureBuilder<SettingsManager>(
      future: getIt.getAsync<SettingsManager>(),
      builder: (context, snapshot) {
        if(!snapshot.hasData) {
          //todo: at some point replace this simple indicator with a proper flash screen
          return CircularProgressIndicator();
        }

        return StreamBuilder<ChoicePreference>(
          initialData: getIt.get<SharedPreferencesService>().loadChoicePreference(theme),
          stream: snapshot.data.updateSettingCommand
            .where((event) => event.key == theme.key)
            .where((event) => event is ChoicePreference)
            .map((event) => event as ChoicePreference),
          builder: (context, snapshot) {
            if(snapshot.data.value == "system") {
              return MaterialApp(
                title: title,
                theme: light,
                darkTheme: dark,
                initialRoute: YagaHomeScreen.route,
                onGenerateRoute: Router.generateRoute,
              );
            }

            return MaterialApp(
              title: title,
              theme: snapshot.data.value == "light" ? light : dark,
              initialRoute: YagaHomeScreen.route,
              onGenerateRoute: Router.generateRoute,
            );
          }
        );
      }
    );
  }
}

