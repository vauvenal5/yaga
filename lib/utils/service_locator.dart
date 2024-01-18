import 'dart:isolate';

import 'package:get_it/get_it.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:yaga/managers/file_manager/file_manager.dart';
import 'package:yaga/managers/file_manager/isolateable/file_action_manager.dart';
import 'package:yaga/managers/file_manager/isolateable/isolated_file_manager.dart';
import 'package:yaga/managers/file_service_manager/isolateable/nextcloud_background_file_manager.dart';
import 'package:yaga/managers/file_service_manager/isolateable/nextcloud_file_manger.dart';
import 'package:yaga/managers/file_service_manager/media_file_manager.dart';
import 'package:yaga/managers/global_settings_manager.dart';
import 'package:yaga/managers/isolateable/isolated_global_settings_manager.dart';
import 'package:yaga/managers/isolateable/isolated_settings_manager.dart';
import 'package:yaga/managers/isolateable/mapping_manager.dart';
import 'package:yaga/managers/isolateable/sort_manager.dart';
import 'package:yaga/managers/isolateable/sync_manager.dart';
import 'package:yaga/managers/navigation_manager.dart';
import 'package:yaga/managers/nextcloud_manager.dart';
import 'package:yaga/managers/settings_manager.dart';
import 'package:yaga/managers/tab_manager.dart';
import 'package:yaga/services/intent_service.dart';
import 'package:yaga/services/isolateable/local_file_service.dart';
import 'package:yaga/services/isolateable/nextcloud_service.dart';
import 'package:yaga/services/isolateable/system_location_service.dart';
import 'package:yaga/services/media_file_service.dart';
import 'package:yaga/services/name_exchange_service.dart';
import 'package:yaga/services/secure_storage_service.dart';
import 'package:yaga/services/shared_preferences_service.dart';
import 'package:yaga/utils/background_worker/background_channel.dart';
import 'package:yaga/utils/background_worker/background_worker.dart';
import 'package:yaga/utils/background_worker/messages/background_init_msg.dart';
import 'package:yaga/utils/background_worker/work_tracker.dart';
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
  getIt.registerSingletonAsync(() async => MediaFileService(
        await getIt.getAsync<SystemLocationService>(),
      ));
  getIt.registerSingletonAsync(() async => MediaFileManager(
        await getIt.getAsync<MediaFileService>(),
      ));
  getIt.registerSingletonAsync(() async => NameExchangeService(
        await getIt.getAsync<MediaFileService>(),
      ));
  getIt.registerSingletonAsync(() async => FileManager(
        await getIt.getAsync<MediaFileManager>(),
        await getIt.getAsync<SharedPreferencesService>(),
        await getIt.getAsync<ForegroundWorker>(),
        await getIt.getAsync<BackgroundWorker>(),
      ));
  getIt.registerSingletonAsync<NextcloudFileManager>(() async =>
      NextcloudFileManager(
          await getIt.getAsync<FileManager>(),
          await getIt.getAsync<NextCloudService>(),
          await getIt.getAsync<LocalFileService>(),
          await getIt.getAsync<MappingManager>(),
          await getIt.getAsync<SyncManager>()));
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
          await getIt.getAsync<SharedPreferencesService>(),
          await getIt.getAsync<SystemLocationService>())
      .init());
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

  getIt.registerSingletonAsync(() async => BackgroundWorker(
        await getIt.getAsync<NextCloudManager>(),
        await getIt.getAsync<SelfSignedCertHandler>(),
      ).init());

  getIt.registerSingletonAsync<FileManagerBridge>(
    () async => FileManagerBridge(
      await getIt.getAsync<FileManager>(),
      await getIt.getAsync<ForegroundWorker>(),
      await getIt.getAsync<MediaFileManager>(),
      await getIt.getAsync<BackgroundWorker>(),
    ),
  );

  getIt.registerSingletonAsync(() async => PackageInfo.fromPlatform());

  getIt.registerSingletonAsync(() async => NavigationManager());
}

//todo: Background: clean up service init for background worker
void setupBackgroundServiceLocator(
  BackgroundInitMsg init,
  BackgroundChannel channel,
) {
  getIt.registerSingletonAsync<SelfSignedCertHandler>(
    () async => SelfSignedCertHandler().initBackgroundable(init.fingerprint),
  );

  // Factories
  getIt.registerSingletonAsync<NextCloudClientFactory>(
    () async => NextCloudClientFactory(
      await getIt.getAsync<SelfSignedCertHandler>(),
    ),
  );

  // Services
  getIt.registerSingletonAsync<LocalFileService>(
    () async => LocalFileService().initBackgroundable(),
  );
  getIt.registerSingletonAsync<NextCloudService>(
    () async => NextCloudService(
      await getIt.getAsync<NextCloudClientFactory>(),
    ).initBackgroundable(init.lastLoginData),
  );

  //Managers
  getIt.registerSingletonAsync<FileActionManager>(
    () async => FileActionManager().initBackground(channel),
  );

  getIt.registerSingletonAsync<NextcloudBackgroundFileManager>(
    () async => NextcloudBackgroundFileManager(
      await getIt.getAsync<NextCloudService>(),
      await getIt.getAsync<LocalFileService>(),
      await getIt.getAsync<FileActionManager>(),
    ).initBackground(),
  );

  getIt.registerSingletonAsync<WorkTracker>(
    () async => WorkTracker(),
  );
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

  getIt.registerSingletonAsync<IsolatedGlobalSettingsManager>(
    () async => IsolatedGlobalSettingsManager(
      await getIt.getAsync<IsolatedSettingsManager>(),
    ).initIsolated(init, isolateToMain),
  );

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
