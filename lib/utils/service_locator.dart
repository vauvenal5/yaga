import 'dart:isolate';

import 'package:get_it/get_it.dart';
import 'package:package_info/package_info.dart';
import 'package:yaga/managers/file_manager.dart';
import 'package:yaga/managers/global_settings_manager.dart';
import 'package:yaga/managers/isolateable/isolated_file_manager.dart';
import 'package:yaga/managers/isolateable/isolated_settings_manager.dart';
import 'package:yaga/managers/isolateable/local_file_manager.dart';
import 'package:yaga/managers/isolateable/mapping_manager.dart';
import 'package:yaga/managers/isolateable/nextcloud_file_manger.dart';
import 'package:yaga/managers/isolateable/sort_manager.dart';
import 'package:yaga/managers/navigation_manager.dart';
import 'package:yaga/managers/nextcloud_manager.dart';
import 'package:yaga/managers/settings_manager.dart';
import 'package:yaga/managers/isolateable/sync_manager.dart';
import 'package:yaga/managers/tab_manager.dart';
import 'package:yaga/services/intent_service.dart';
import 'package:yaga/services/isolateable/local_file_service.dart';
import 'package:yaga/services/isolateable/nextcloud_service.dart';
import 'package:yaga/services/secure_storage_service.dart';
import 'package:yaga/services/shared_preferences_service.dart';
import 'package:yaga/services/isolateable/system_location_service.dart';
import 'package:yaga/utils/forground_worker/bridges/file_manager_bridge.dart';
import 'package:yaga/utils/forground_worker/bridges/nextcloud_manager_bridge.dart';
import 'package:yaga/utils/forground_worker/bridges/settings_manager_bridge.dart';
import 'package:yaga/utils/forground_worker/foreground_worker.dart';
import 'package:yaga/utils/forground_worker/handlers/file_list_request_handler.dart';
import 'package:yaga/utils/forground_worker/handlers/nextcloud_file_manager_handler.dart';
import 'package:yaga/utils/forground_worker/handlers/user_handler.dart';
import 'package:yaga/utils/forground_worker/isolate_handler_regestry.dart';
import 'package:yaga/utils/forground_worker/messages/init_msg.dart';
import 'package:yaga/utils/nextcloud_client_factory.dart';
import 'package:yaga/utils/self_signed_cert_handler.dart';

GetIt getIt = GetIt.instance;

void setupServiceLocator() {
  //setup HTTP overrides
  getIt.registerSingletonAsync<SecureStorageService>(
    () => SecureStorageService().init(),
  );
  getIt.registerSingletonAsync<SelfSignedCertHandler>(
    () async => SelfSignedCertHandler().init(
      await getIt.getAsync<SecureStorageService>(),
    ),
  );

  // Factories
  getIt.registerSingletonAsync<NextCloudClientFactory>(
    () async => NextCloudClientFactory(
      await getIt.getAsync<SelfSignedCertHandler>(),
    ),
  );

  // Services
  getIt.registerSingletonAsync<SystemLocationService>(
      () => SystemLocationService().init());
  getIt.registerSingletonAsync<LocalFileService>(
      () async => LocalFileService().init());
  getIt.registerSingletonAsync<SharedPreferencesService>(
      () => SharedPreferencesService().init());
  getIt.registerSingletonAsync<NextCloudService>(() async => NextCloudService(
        await getIt.getAsync<NextCloudClientFactory>(),
      ).init());

  getIt.registerSingletonAsync<IntentService>(
      () async => IntentService().init());

  //todo: re-check if we still need everything in the main thread (bridge strategy)
  // Managers
  getIt.registerSingletonAsync<TabManager>(() async => TabManager());
  getIt.registerSingletonAsync<SettingsManager>(() async => SettingsManager(
        await getIt.getAsync<SharedPreferencesService>(),
      ));
  getIt.registerSingletonAsync<NextCloudManager>(
    () async => NextCloudManager(
      await getIt.getAsync<NextCloudService>(),
      await getIt.getAsync<SecureStorageService>(),
      await getIt.getAsync<LocalFileService>(),
      await getIt.getAsync<SystemLocationService>(),
      await getIt.getAsync<SelfSignedCertHandler>(),
    ).init(),
  );
  getIt.registerSingletonAsync(() async => MappingManager(
      await getIt.getAsync<SettingsManager>(),
      await getIt.getAsync<NextCloudService>(),
      await getIt.getAsync<SystemLocationService>()));
  getIt.registerSingletonAsync(() async => SyncManager());
  getIt.registerSingletonAsync(() async => FileManager(
      await getIt.getAsync<NextCloudService>(),
      await getIt.getAsync<LocalFileService>()));
  getIt.registerSingletonAsync<NextcloudFileManager>(() async =>
      NextcloudFileManager(
          await getIt.getAsync<FileManager>(),
          await getIt.getAsync<NextCloudService>(),
          await getIt.getAsync<LocalFileService>(),
          await getIt.getAsync<MappingManager>(),
          await getIt.getAsync<SyncManager>()));
  getIt.registerSingletonAsync<LocalFileManager>(() async => LocalFileManager(
        await getIt.getAsync<FileManager>(),
        await getIt.getAsync<LocalFileService>(),
        await getIt.getAsync<SystemLocationService>(),
      ));
  getIt.registerSingletonAsync<GlobalSettingsManager>(
      () async => GlobalSettingsManager(
            await getIt.getAsync<NextCloudManager>(),
            await getIt.getAsync<SettingsManager>(),
            await getIt.getAsync<NextCloudService>(),
            await getIt.getAsync<SystemLocationService>(),
          ).init());

  getIt.registerSingletonAsync<ForegroundWorker>(() async => ForegroundWorker(
        await getIt.getAsync<NextCloudManager>(),
        await getIt.getAsync<GlobalSettingsManager>(),
        await getIt.getAsync<SelfSignedCertHandler>(),
      ).init());
  getIt.registerSingletonAsync<NextcloudManagerBridge>(
      () async => NextcloudManagerBridge(
            await getIt.getAsync<NextCloudManager>(),
            await getIt.getAsync<ForegroundWorker>(),
            await getIt.getAsync<NextcloudFileManager>(),
          ));
  getIt.registerSingletonAsync<SettingsManagerBridge>(
    () async => SettingsManagerBridge(
      await getIt.getAsync<SettingsManager>(),
      await getIt.getAsync<ForegroundWorker>(),
    ).init(),
  );
  getIt.registerSingletonAsync<FileManagerBridge>(
    () async => FileManagerBridge(
      await getIt.getAsync<FileManager>(),
      await getIt.getAsync<ForegroundWorker>(),
    ),
  );

  getIt.registerSingletonAsync(() async => await PackageInfo.fromPlatform());

  getIt.registerSingletonAsync(() async => NavigationManager());
}

void setupIsolatedServiceLocator(
  InitMsg init,
  SendPort isolateToMain,
  IsolateHandlerRegistry registry,
) {
  getIt.registerSingletonAsync<SelfSignedCertHandler>(
    () async => SelfSignedCertHandler().initIsolated(init, isolateToMain),
  );

  // Factories
  getIt.registerSingletonAsync<NextCloudClientFactory>(
    () async => NextCloudClientFactory(
      await getIt.getAsync<SelfSignedCertHandler>(),
    ),
  );

  // Services
  getIt.registerSingletonAsync<SystemLocationService>(
    () async => SystemLocationService().initIsolated(init, isolateToMain),
  );
  getIt.registerSingletonAsync<LocalFileService>(
    () async => LocalFileService().initIsolated(init, isolateToMain),
  );
  getIt.registerSingletonAsync<NextCloudService>(
    () async => NextCloudService(
      await getIt.getAsync<NextCloudClientFactory>(),
    ).initIsolated(init, isolateToMain),
  );

  // Managers
  getIt.registerSingletonAsync(
    () async => SortManager().initIsolated(init, isolateToMain),
  );
  getIt.registerSingletonAsync(
    () async => IsolatedFileManager(
      await getIt.getAsync<SortManager>(),
    ).initIsolated(init, isolateToMain),
  );
  getIt.registerSingletonAsync(
      () async => IsolatedSettingsManager().initIsolated(init, isolateToMain));
  getIt.registerSingletonAsync(
      () async => SyncManager().initIsolated(init, isolateToMain));

  getIt.registerSingletonAsync(() async => MappingManager(
          await getIt.getAsync<IsolatedSettingsManager>(),
          await getIt.getAsync<NextCloudService>(),
          await getIt.getAsync<SystemLocationService>())
      .initIsolated(init, isolateToMain));

  getIt.registerSingletonAsync<NextcloudFileManager>(() async =>
      NextcloudFileManager(
              await getIt.getAsync<IsolatedFileManager>(),
              await getIt.getAsync<NextCloudService>(),
              await getIt.getAsync<LocalFileService>(),
              await getIt.getAsync<MappingManager>(),
              await getIt.getAsync<SyncManager>())
          .initIsolated(init, isolateToMain));

  getIt.registerSingletonAsync<LocalFileManager>(() async => LocalFileManager(
        await getIt.getAsync<IsolatedFileManager>(),
        await getIt.getAsync<LocalFileService>(),
        await getIt.getAsync<SystemLocationService>(),
      ).initIsolated(init, isolateToMain));

  // Handlers
  getIt.registerSingletonAsync<NextcloudFileManagerHandler>(
    () async => NextcloudFileManagerHandler(
      await getIt.getAsync<NextcloudFileManager>(),
      isolateToMain,
    ).initIsolated(
      init,
      isolateToMain,
      registry,
    ),
  );

  getIt.registerSingletonAsync<FileListRequestHandler>(
    () async => FileListRequestHandler().initIsolated(
      init,
      isolateToMain,
      registry,
    ),
  );

  getIt.registerSingletonAsync<UserHandler>(
    () async => UserHandler().initIsolated(
      init,
      isolateToMain,
      registry,
    ),
  );
}
