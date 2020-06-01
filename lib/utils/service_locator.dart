import 'package:get_it/get_it.dart';
import 'package:yaga/managers/settings_manager.dart';
import 'package:yaga/services/local_image_provider_service.dart';
import 'package:yaga/services/shared_preferences_service.dart';

GetIt getIt = GetIt.instance;

void setupServiceLocator() {
  getIt.registerSingleton<LocalImageProviderService>(LocalImageProviderService());
  getIt.registerSingleton<SharedPreferencesService>(SharedPreferencesService());

  getIt.registerSingleton<SettingsManager>(SettingsManager());
}