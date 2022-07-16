import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:rx_command/rx_command.dart';
import 'package:yaga/managers/isolateable/mapping_manager.dart';
import 'package:yaga/managers/settings_manager_base.dart';
import 'package:yaga/model/nc_origin.dart';
import 'package:yaga/model/preferences/mapping_preference.dart';
import 'package:yaga/model/preferences/preference.dart';
import 'package:yaga/model/system_location.dart';
import 'package:yaga/services/isolateable/nextcloud_service.dart';
import 'package:yaga/services/isolateable/system_location_service.dart';
import 'mapping_manager_test.mocks.dart';

@GenerateMocks([SettingsManagerBase, NextCloudService, SystemLocationService])
void main() {
  final MockSettingsManagerBase settingsManagerBaseMock =
      MockSettingsManagerBase();
  final MockNextCloudService nextCloudServiceMock = MockNextCloudService();
  final MockSystemLocationService systemLocationServiceMock =
      MockSystemLocationService();

  const userInfo = "yaga";
  const host = "cloud.test.com";
  const userDomain = "$userInfo@$host";

  final ncRoot = Uri(host: host, pathSegments: []);
  final ncOrigin = NcOrigin(ncRoot, userInfo, userInfo, userInfo);

  final command = MockCommand<Preference, Preference>();

  final origin = Uri(scheme: 'file', host: 'device.local', path: '/');
  final SystemLocation internalAppDirStorage = SystemLocation.fromSplitter(
      Directory('/system/path/Android/app/path'), origin, 'Android');
  final internalAppDirCache = SystemLocation.fromSplitter(
      Directory('/system/path/Android/cache/path'), origin, 'Android');

  const localPath = "/some/local/path";

  late MappingManager uut;

  setUp(() async {
    when(settingsManagerBaseMock.updateSettingCommand).thenAnswer((_) => command);

    when(nextCloudServiceMock.origin).thenReturn(ncOrigin);

    when(systemLocationServiceMock.internalStorage).thenReturn(internalAppDirStorage);
    when(systemLocationServiceMock.internalCache).thenReturn(internalAppDirCache);
    when(systemLocationServiceMock.absoluteUriFromInternal(any)).thenAnswer((realInvocation) => realInvocation.positionalArguments[0] as Uri);

    uut = MappingManager(
      settingsManagerBaseMock,
      nextCloudServiceMock,
      systemLocationServiceMock,
    );
  });

  void setUpMapping(String localPath, String remotePath) {
    final MappingPreference pref = MappingPreference((b) => b
      ..key = "testKey"
      ..title = "Root Mapping"
      ..value = false
      ..local.value = Uri(host: "local", path: localPath)
      ..remote.value = Uri(host: "remote", path: remotePath));

    uut.handleMappingUpdate(pref);
  }

  group("map to tmp path", () {
    Future<void> mapToTmpPathTest(String remotePath) async {
      await uut.mapToTmpUri(Uri(host: "remote", path: remotePath));

      final Uri captured = verify(systemLocationServiceMock.absoluteUriFromInternal(captureAny))
          .captured
          .single as Uri;

      expect(captured.path, "${internalAppDirCache.uri.path}/$userDomain$remotePath");
    }

    test("default mapps to cache dir", () async {
      const String remote = "/test/1.png";
      mapToTmpPathTest(remote);
    });

    test("mappings do not influence tmp", () async {
      const String remote = "/test/1.png";
      setUpMapping(localPath, "/");
      mapToTmpPathTest(remote);
    });
  });

  group("map to local path", () {
    Future<void> mapToLocalPathTest({
      required String remotePath,
      String? remoteTargetFolderPath,
      required String expectedPath,
    }) async {
      if (remoteTargetFolderPath != null) {
        setUpMapping(localPath, remoteTargetFolderPath);
      }

      await uut.mapToLocalUri(Uri(host: "remote", path: remotePath));

      final Uri captured = verify(systemLocationServiceMock.absoluteUriFromInternal(captureAny))
          .captured
          .single as Uri;

      expect(captured.path, expectedPath);
    }

    Future<void> mapRootToLocalPathTest(String remotePath) async {
      mapToLocalPathTest(
        remotePath: remotePath,
        remoteTargetFolderPath: "/",
        expectedPath: localPath + remotePath,
      );
    }

    Future<void> mapPicturesToLocalPathTest(String remotePath,
        {String? expectedPath}) async {
      const String targetPath = "/Pictures/";
      mapToLocalPathTest(
        remotePath: remotePath,
        remoteTargetFolderPath: targetPath,
        expectedPath: expectedPath ??
            localPath + remotePath.replaceFirst(targetPath, "/"),
      );
    }

    test("file with root mapping", () async {
      const String remote = "/test/1.png";
      mapRootToLocalPathTest(remote);
    });

    test("dir with root mapping", () async {
      const String remote = "/test/";
      mapRootToLocalPathTest(remote);
    });

    test("file with sub mapping", () async {
      const String remote = "/Pictures/1.png";
      mapPicturesToLocalPathTest(remote);
    });

    test("dir with sub mapping", () async {
      const String remote = "/Pictures/test/";
      mapPicturesToLocalPathTest(remote);
    });

    test("none sub mapping paths are mapped to app dir", () async {
      const String remote = "/test/1.png";
      mapPicturesToLocalPathTest(remote,
          expectedPath: "${internalAppDirStorage.uri.path}/$userDomain$remote");
    });

    test("default mapps to app dir", () async {
      const String remote = "/test/1.png";
      mapToLocalPathTest(
          remotePath: remote,
          expectedPath: "${internalAppDirStorage.uri.path}/$userDomain$remote");
    });
  });

  group("map tmp to remote uri", () {
    Future<void> mapTmpToRemoteUriTest(String relativePath) async {
      final Uri tmp = Uri(
        host: "local",
        path: "${internalAppDirCache.uri.path}/$userDomain$relativePath",
      );
      final Uri remote = Uri(
        scheme: "nc",
        userInfo: userInfo,
        host: host,
        pathSegments: [],
      );

      final Uri result = await uut.mapTmpToRemoteUri(tmp, remote);

      expect(result.scheme, "nc");
      expect(result.userInfo, userInfo);
      expect(result.host, host);
      expect(result.path, relativePath);
    }

    test("map tmp file", () async {
      mapTmpToRemoteUriTest("/test/1.png");
    });

    test("map tmp dir", () async {
      mapTmpToRemoteUriTest("/test/");
    });
  });

  group("map to remote uri", () {
    Future<void> mapToRemoteUriTest({
      required String localFilePath,
      required String remotePath,
      required String expectedPath,
      String? mappingPath,
    }) async {
      final Uri file = Uri(
        host: "local",
        path: localFilePath,
      );
      final Uri remote = Uri(
        scheme: "nc",
        userInfo: userInfo,
        host: host,
        path: remotePath,
      );

      if (mappingPath != null) {
        setUpMapping(localPath, mappingPath);
      }

      final Uri result = await uut.mapToRemoteUri(file, remote);

      expect(result.scheme, "nc");
      expect(result.userInfo, userInfo);
      expect(result.host, host);
      expect(result.path, expectedPath);
    }

    test("map file with default mapping", () async {
      mapToRemoteUriTest(
        localFilePath:
            "${internalAppDirStorage.uri.path}/$userDomain/test/1.png",
        remotePath: "/",
        expectedPath: "/test/1.png",
      );
    });

    test("map file with root mapping", () async {
      mapToRemoteUriTest(
        localFilePath: "$localPath/test/1.png",
        remotePath: "/",
        expectedPath: "/test/1.png",
        mappingPath: "/",
      );
    });

    test("map file with sub mapping", () async {
      mapToRemoteUriTest(
        localFilePath: "$localPath/test/1.png",
        remotePath: "/Pictures/",
        expectedPath: "/Pictures/test/1.png",
        mappingPath: "/Pictures/",
      );
    });

    test("map file on different path than sub mapping", () async {
      mapToRemoteUriTest(
        localFilePath:
            "${internalAppDirStorage.uri.path}/$userDomain/test/1.png",
        remotePath: "/",
        expectedPath: "/test/1.png",
        mappingPath: "/Pictures/",
      );
    });
  });
}
