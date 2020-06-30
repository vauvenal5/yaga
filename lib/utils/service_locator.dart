import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yaga/managers/file_manager.dart';
import 'package:yaga/managers/mapping_manager.dart';
import 'package:yaga/managers/nextcloud_manager.dart';
import 'package:yaga/managers/settings_manager.dart';
import 'package:yaga/services/local_image_provider_service.dart';
import 'package:yaga/services/nextcloud_service.dart';
import 'package:yaga/services/secure_storage_service.dart';
import 'package:yaga/services/shared_preferences_service.dart';

GetIt getIt = GetIt.instance;

void setupServiceLocator() {

  // Services
  getIt.registerSingletonAsync<LocalImageProviderService>(() => LocalImageProviderService().init());
  getIt.registerSingletonAsync<SharedPreferencesService>(() => SharedPreferencesService().init());
  getIt.registerSingletonAsync<NextCloudService>(() => NextCloudService().init());
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
    await getIt.getAsync<LocalImageProviderService>()
  ));
  getIt.registerSingletonAsync(() async => FileManager(
    await getIt.getAsync<NextCloudService>(),
    await getIt.getAsync<LocalImageProviderService>(),
    await getIt.getAsync<MappingManager>()
  ));
}