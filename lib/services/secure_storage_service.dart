import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:yaga/services/service.dart';

class SecureStorageService extends Service<SecureStorageService> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<void> savePreference(String key, String value) {
    return _storage.write(key: key, value: value).catchError(_logAndRethrow);
  }

  Future<String> loadPreference(String key) {
    return _storage
        .read(key: key)
        .catchError(_logAndRethrow)
        .then((value) => value ?? "");
  }

  Future<void> deletePreference(String key) {
    return _storage.delete(key: key).catchError(_logAndRethrow);
  }

  void _logAndRethrow(Object err) {
    if (err is PlatformException) {
      logger.severe("SecureStorage: ${err.code}");
      logger.severe("SecureStorage: ${err.message}");
      logger.severe("SecureStorage: ${err.details}");
      logger.severe("SecureStorage: ${err.stacktrace}");
    } else {
      logger.severe(err);
    }
    throw err;
  }
}
