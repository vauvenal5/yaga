import 'package:flutter/material.dart';
import 'package:yaga/managers/tab_manager.dart';
import 'package:yaga/utils/forground_worker/foreground_worker.dart';
import 'package:yaga/utils/service_locator.dart';
import 'package:yaga/views/screens/home_view.dart';
import 'package:yaga/views/screens/browse_view.dart';

//todo: this has to be renamed
enum YagaHomeTab { grid, folder }

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
    return StreamBuilder<YagaHomeTab>(
      initialData: YagaHomeTab.grid,
      stream: getIt.get<TabManager>().tabChangedCommand,
      builder: (context, snapshot) {
        return IndexedStack(
          index: _getCurrentIndex(snapshot.data),
          children: <Widget>[HomeView(), BrowseView()],
        );
      },
    );
  }

  int _getCurrentIndex(YagaHomeTab tab) {
    switch (tab) {
      case YagaHomeTab.folder:
        return 1;
      default:
        return 0;
    }
  }
}
