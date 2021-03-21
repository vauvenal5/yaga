import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:yaga/services/service.dart';

class SecureStorageService extends Service<SecureStorageService> {
  FlutterSecureStorage _storage;

  SecureStorageService() {
    _storage = new FlutterSecureStorage();
  }

  Future<void> savePreference(String key, String value) {
    return this
        ._storage
        .write(key: key, value: value)
        .catchError(_logAndRethrow);
  }

  Future<String> loadPreference(String key) {
    return this
        ._storage
        .read(key: key)
        .catchError(_logAndRethrow)
        .then((value) => value ?? "");
  }

  Future<void> deletePreference(String key) {
    return this._storage.delete(key: key).catchError(_logAndRethrow);
  }

  void _logAndRethrow(dynamic err) {
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
