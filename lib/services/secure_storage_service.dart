import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  FlutterSecureStorage _storage;

  SecureStorageService() {
    _storage = new FlutterSecureStorage();
  }

  Future<void> savePreference(String key, String value) {
    return this._storage.write(key: key, value: value);
  }

  Future<String> loadPreference(String key) {
    return this._storage.read(key: key).then((value) => value??"");
  }
}