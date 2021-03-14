import 'dart:io';
import 'dart:isolate';

import 'package:yaga/services/secure_storage_service.dart';
import 'package:yaga/utils/forground_worker/isolateable.dart';
import 'package:yaga/utils/forground_worker/messages/init_msg.dart';
import 'package:yaga/utils/logger.dart';

class SelfSignedCertHandler extends HttpOverrides
    implements Isolateable<SelfSignedCertHandler> {
  final _logger = getLogger(SelfSignedCertHandler);

  final String _fingerprintKey = "cert.fingerprint";
  String _fingerprint;

  /// Expects a callback function if the cert is to be accepted and null otherwise.
  /// This callback function is then used to notify the caller when cert has been accepted.
  Future<Function> Function(String subject, String issuer, String fingerprint)
      badCertificateCallback;

  SecureStorageService _secureStorageService;

  Future<SelfSignedCertHandler> init(SecureStorageService secStorage) async {
    this._secureStorageService = secStorage;
    this._fingerprint = await _secureStorageService.loadPreference(
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
    this._fingerprint = init.fingerprint;
    HttpOverrides.global = this;
    return this;
  }

  String get fingerprint => _fingerprint;

  @override
  HttpClient createHttpClient(SecurityContext context) {
    final HttpClient client = super.createHttpClient(context);
    client.badCertificateCallback =
        (X509Certificate cert, String host, int port) {
      String certFingerprint = cert.sha1.toString();
      if (_fingerprint == certFingerprint && cert.subject.endsWith(host)) {
        return true;
      }

      _logger.w("Fingerprint Cert: $certFingerprint");
      _logger.w("Saved Fingerprint: $_fingerprint");
      _logger.w("Host: $host");
      _logger.w("Cert-Subject: ${cert.subject}");

      badCertificateCallback
          ?.call(
        cert.subject,
        cert.issuer,
        certFingerprint,
      )
          ?.then((certAcceptedCallback) {
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
    return this
            ._secureStorageService
            ?.savePreference("$_fingerprintKey", _fingerprint) ??
        Future.value();
  }

  void revokeCert() {
    this._fingerprint = null;
    this._secureStorageService?.deletePreference(this._fingerprintKey);
  }
}
