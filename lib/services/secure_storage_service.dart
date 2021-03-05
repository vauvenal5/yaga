import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';
import 'package:yaga/services/service.dart';
import 'package:yaga/utils/logger.dart';

class SecureStorageService extends Service<SecureStorageService> {
  final Logger _logger = getLogger(SecureStorageService);
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
      _logger.e("SecureStorage: ${err.code}");
      _logger.e("SecureStorage: ${err.message}");
      _logger.e("SecureStorage: ${err.details}");
      _logger.e("SecureStorage: ${err.stacktrace}");
    } else {
      _logger.e(err);
    }
    throw err;
  }
}
