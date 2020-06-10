import 'package:get_it/get_it.dart';
import 'package:yaga/managers/file_manager.dart';
import 'package:yaga/managers/nextcloud_manager.dart';
import 'package:yaga/managers/settings_manager.dart';
import 'package:yaga/services/local_image_provider_service.dart';
import 'package:yaga/services/nextcloud_service.dart';
import 'package:yaga/services/secure_storage_service.dart';
import 'package:yaga/services/shared_preferences_service.dart';

GetIt getIt = GetIt.instance;

void setupServiceLocator() {
  getIt.registerSingleton(LocalImageProviderService());
  getIt.registerSingleton(SharedPreferencesService());
  getIt.registerSingleton(NextCloudService());
  getIt.registerSingleton(SecureStorageService());

  getIt.registerSingleton(SettingsManager());
  getIt.registerSingleton(NextCloudManager());
  getIt.registerSingleton(FileManager());
}