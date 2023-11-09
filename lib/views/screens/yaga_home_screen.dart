import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:yaga/managers/global_settings_manager.dart';
import 'package:yaga/managers/tab_manager.dart';
import 'package:yaga/services/shared_preferences_service.dart';
import 'package:yaga/utils/forground_worker/foreground_worker.dart';
import 'package:yaga/utils/service_locator.dart';
import 'package:yaga/views/screens/favorites_view.dart';
import 'package:yaga/views/screens/home_view.dart';
import 'package:yaga/views/screens/browse_view.dart';
import 'package:yaga/views/widgets/yaga_about_dialog.dart';

//todo: this has to be renamed
enum YagaHomeTab { grid, folder, favorites }

class YagaHomeScreen extends StatefulWidget {
  static const String route = "home://";

  @override
  _YagaHomeScreenState createState() => _YagaHomeScreenState();
}

class _YagaHomeScreenState extends State<YagaHomeScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      getIt.get<ForegroundWorker>().dispose();
    }

    if (state == AppLifecycleState.resumed) {
      getIt.get<ForegroundWorker>().init();
    }
  }

  @override
  Widget build(BuildContext context) {
    _showNewsDialog(context);

    return StreamBuilder<YagaHomeTab>(
      initialData: YagaHomeTab.grid,
      stream: getIt.get<TabManager>().tabChangedCommand,
      builder: (context, snapshot) {
        return IndexedStack(
          index: _getCurrentIndex(snapshot.data),
          children: <Widget>[HomeView(), FavoritesView(), BrowseView()],
        );
      },
    );
  }

  int _getCurrentIndex(YagaHomeTab? tab) {
    switch (tab) {
      case YagaHomeTab.folder:
        return 2;
      case YagaHomeTab.favorites:
        return 1;
      default:
        return 0;
    }
  }

  void _showNewsDialog(BuildContext context) {
    Future.delayed(Duration.zero, () async {
      final sharedPrefService = getIt.get<SharedPreferencesService>();
      final version = getIt.get<PackageInfo>().version;

      if (sharedPrefService
          .loadPreferenceFromString(GlobalSettingsManager.newsSeenVersion)
          .value !=
          version) {
        await showDialog(
          context: context,
          builder: (BuildContext context) => YagaAboutDialog(),
        ).whenComplete(
              () => sharedPrefService.savePreferenceToString(
            GlobalSettingsManager.newsSeenVersion
                .rebuild((b) => b..value = version),
          ),
        );
      }
    });
  }
}
