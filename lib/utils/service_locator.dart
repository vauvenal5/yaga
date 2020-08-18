import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yaga/managers/file_manager.dart';
import 'package:yaga/managers/local_file_manager.dart';
import 'package:yaga/managers/mapping_manager.dart';
import 'package:yaga/managers/nextcloud_file_manger.dart';
import 'package:yaga/managers/nextcloud_manager.dart';
import 'package:yaga/managers/settings_manager.dart';
import 'package:yaga/managers/sync_manager.dart';
import 'package:yaga/services/local_file_service.dart';
import 'package:yaga/services/local_image_provider_service.dart';
import 'package:yaga/services/nextcloud_service.dart';
import 'package:yaga/services/secure_storage_service.dart';
import 'package:yaga/services/shared_preferences_service.dart';
import 'package:yaga/services/system_location_service.dart';
import 'package:yaga/utils/nextcloud_client_factory.dart';

GetIt getIt = GetIt.instance;

void setupServiceLocator() {
  // Factories
  getIt.registerSingletonAsync<NextCloudClientFactory>(() async => NextCloudClientFactory());

  // Services
  getIt.registerSingletonAsync<SystemLocationService>(() => SystemLocationService().init());
  // getIt.registerSingletonAsync<LocalImageProviderService>(()  async => LocalImageProviderService(
  //   await getIt.getAsync<SystemLocationService>()
  // ).init());
  getIt.registerSingletonAsync<LocalFileService>(() async => LocalFileService().init());
  getIt.registerSingletonAsync<SharedPreferencesService>(() => SharedPreferencesService().init());
  getIt.registerSingletonAsync<NextCloudService>(() async => NextCloudService(
    await getIt.getAsync<NextCloudClientFactory>(),
  ).init());
  getIt.registerSingletonAsync<SecureStorageService>(() => SecureStorageService().init());

  // Managers
  getIt.registerSingletonAsync<SettingsManager>(() async => SettingsManager(
    await getIt.getAsync<SharedPreferencesService>(),
  ));
  getIt.registerSingletonAsync<NextCloudManager>(() async => NextCloudManager(
    await getIt.getAsync<NextCloudService>(),
    await getIt.getAsync<SecureStorageService>()
  ));
  getIt.registerSingletonAsync(() async => MappingManager(
    await getIt.getAsync<SettingsManager>(),
    await getIt.getAsync<NextCloudService>(),
    await getIt.getAsync<SystemLocationService>()
  ));
  getIt.registerSingletonAsync(() async => SyncManager());
  getIt.registerSingletonAsync(() async => FileManager(
    await getIt.getAsync<NextCloudService>(),
    await getIt.getAsync<LocalFileService>()
  ));
  getIt.registerSingletonAsync<NextcloudFileManager>(() async => NextcloudFileManager(
    await getIt.getAsync<FileManager>(), 
    await getIt.getAsync<NextCloudService>(), 
    await getIt.getAsync<LocalFileService>(), 
    await getIt.getAsync<MappingManager>(), 
    await getIt.getAsync<SyncManager>()
  ).init());
  getIt.registerSingletonAsync<LocalFileManager>(() async => LocalFileManager(
    await getIt.getAsync<FileManager>(), 
    await getIt.getAsync<LocalFileService>(), 
    await getIt.getAsync<SystemLocationService>(), 
  ).init());
}