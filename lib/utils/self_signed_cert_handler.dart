import 'dart:io';
import 'dart:isolate';

import 'package:yaga/services/secure_storage_service.dart';
import 'package:yaga/utils/forground_worker/isolateable.dart';
import 'package:yaga/utils/forground_worker/messages/init_msg.dart';
import 'package:yaga/utils/logger.dart';

class SelfSignedCertHandler extends HttpOverrides
    implements Isolateable<SelfSignedCertHandler> {
  final _logger = YagaLogger.getLogger(SelfSignedCertHandler);

  final String _fingerprintKey = "cert.fingerprint";
  String? _fingerprint;

  /// Expects a callback function if the cert is to be accepted and null otherwise.
  /// This callback function is then used to notify the caller when cert has been accepted.
  Future<Function?> Function(String subject, String issuer, String fingerprint)?
      badCertificateCallback;

  SecureStorageService? _secureStorageService;

  Future<SelfSignedCertHandler> init(SecureStorageService secStorage) async {
    _secureStorageService = secStorage;
    _fingerprint = await _secureStorageService?.loadPreference(
      _fingerprintKey,
    );
    HttpOverrides.global = this;
    return this;
  }

  @override
  Future<SelfSignedCertHandler> initIsolated(
    InitMsg init,
    SendPort isolateToMain,
  ) async {
    _fingerprint = init.fingerprint;
    HttpOverrides.global = this;
    return this;
  }

  String get fingerprint => _fingerprint ?? '';

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final HttpClient client = super.createHttpClient(context);
    client.badCertificateCallback =
        (X509Certificate cert, String host, int port) {
      final String certFingerprint = cert.sha1.toString();
      if (_fingerprint == certFingerprint) {
        return true;
      }

      _logger.warning("Fingerprint Cert: $certFingerprint");
      _logger.warning("Saved Fingerprint: $_fingerprint");
      _logger.warning("Host: $host");
      _logger.warning("Cert-Subject: ${cert.subject}");

      badCertificateCallback
          ?.call(
        cert.subject,
        cert.issuer,
        certFingerprint,
      )
          .then((certAcceptedCallback) {
        if (certAcceptedCallback != null) {
          // we are here temporarily accepting the cert but not persisting until a successfull login
          _fingerprint = certFingerprint;
          certAcceptedCallback();
        }
      });
      return false;
    };
    return client;
  }

  Future<void> persistCert() {
    return _secureStorageService?.savePreference(
            _fingerprintKey, fingerprint) ??
        Future.value();
  }

  void revokeCert() {
    _fingerprint = null;
    _secureStorageService?.deletePreference(_fingerprintKey);
  }
}
