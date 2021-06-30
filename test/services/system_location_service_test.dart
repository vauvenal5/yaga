import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:yaga/model/system_location_host.dart';
import 'package:yaga/services/isolateable/system_location_service.dart';

class MockPathProviderPlatform extends Mock with MockPlatformInterfaceMixin implements PathProviderPlatform {}

void main() {
  const String localRoot = "/bla/emulated/0";
  const String localPublic = "/Android/data/bla/files";
  const String tmpRoot = "/bla/user/0";
  const String tmpPublic = "/cache/data/bla/files";
  const String localHost = "device.local";
  const String tmpHost = "device.tmp";

  final SystemLocationService uut = SystemLocationService();

  setUpAll(() async {
    PathProviderPlatform.instance = MockPathProviderPlatform();
    // This is required because we manually register the Linux path provider when on the Linux platform.
    // Will be removed when automatic registration of dart plugins is implemented.
    // See this issue https://github.com/flutter/flutter/issues/52267 for details
    // ignore: deprecated_member_use
    disablePathProviderPlatformOverride = true;

    when(PathProviderPlatform.instance.getExternalStoragePath()).thenAnswer((_) => Future.value(localRoot+localPublic));
    when(PathProviderPlatform.instance.getTemporaryPath()).thenAnswer((_) => Future.value(tmpRoot+tmpPublic));

    await uut.init();
  });

  group("getOrigin", () {
    test("should return correct default origin", () async {
      final Uri actual = uut.getOrigin();

      expect(actual, equals(Uri(scheme: "file", host: localHost, path: "")));
    });

    test("should return correct local origin", () async {
      final Uri actual = uut.getOrigin(host: SystemLocationHost.local);

      expect(actual, equals(Uri(scheme: "file", host: localHost, path: "")));
    });

    test("should return correct tmp origin", () async {
      final Uri actual = uut.getOrigin(host: SystemLocationHost.tmp);

      expect(actual, equals(Uri(scheme: "file", host: tmpHost, path: "")));
    });
  });

  group("internalUriFromAbsolute", () {
    test("should return local uri with argument", () async {
      const String file = "$localPublic/test/myFile.jpeg";
      final Uri actual = uut.internalUriFromAbsolute(Uri(scheme: "file", path: localRoot+file), host: SystemLocationHost.local);
      expect(actual, equals(Uri(scheme: "file", host: localHost, path: file)));
    });
    test("should return local uri", () async {
      const String file = "$localPublic/test/myFile.jpeg";
      final Uri actual = uut.internalUriFromAbsolute(Uri(scheme: "file", path: localRoot+file));
      expect(actual, equals(Uri(scheme: "file", host: localHost, path: file)));
    });
    test("should return tmp uri with argument", () async {
      const String file = "$tmpPublic/test/myFile.jpeg";
      final Uri actual = uut.internalUriFromAbsolute(Uri(scheme: "file", path: tmpRoot+file), host: SystemLocationHost.tmp);
      expect(actual, equals(Uri(scheme: "file", host: tmpHost, path: file)));
    });
    test("should return tmp uri", () async {
      const String file = "$tmpPublic/test/myFile.jpeg";
      final Uri actual = uut.internalUriFromAbsolute(Uri(scheme: "file", path: tmpRoot+file));
      expect(actual, equals(Uri(scheme: "file", host: tmpHost, path: file)));
    });
  });

  group("absoluteUriFromInternal", () {
    test("should return absolute uri from local", () {
      const String file = "$localPublic/test/myFile.jpeg";
      final Uri actual = uut.absoluteUriFromInternal(Uri(scheme: "file", host: localHost, path: file));
      expect(actual, equals(Uri(scheme: "file", path: localRoot+file)));
    });
    test("should return absolute uri from tmp", () {
      const String file = "$tmpPublic/test/myFile.jpeg";
      final Uri actual = uut.absoluteUriFromInternal(Uri(scheme: "file", host: tmpHost, path: file));
      expect(actual, equals(Uri(scheme: "file", path: tmpRoot+file)));
    });
  });

  group("rootDirectories", () {
    test("should return local root url", () {
      expect(uut.externalAppDirUri, equals(Uri(scheme: "file", host: localHost, path: localPublic)));
    });
    test("should return tmp root url", () {
      expect(uut.tmpAppDirUri, equals(Uri(scheme: "file", host: tmpHost, path: tmpPublic)));
    });
  });
}