import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:rx_command/rx_command.dart';
import 'package:yaga/managers/isolateable/mapping_manager.dart';
import 'package:yaga/managers/settings_manager_base.dart';
import 'package:yaga/model/preferences/mapping_preference.dart';
import 'package:yaga/model/preferences/preference.dart';
import 'package:yaga/services/isolateable/nextcloud_service.dart';
import 'package:yaga/services/isolateable/system_location_service.dart';

class SettingsManagerBaseMock extends Mock implements SettingsManagerBase {}

class NextCloudServiceMock extends Mock implements NextCloudService {}

class SystemLocationServiceMock extends Mock implements SystemLocationService {}

void main() {
  SettingsManagerBaseMock settingsManagerBaseMock = SettingsManagerBaseMock();
  NextCloudServiceMock nextCloudServiceMock = NextCloudServiceMock();
  SystemLocationServiceMock systemLocationServiceMock =
      SystemLocationServiceMock();

  final ncRoot = Uri(host: "nc", pathSegments: []);
  final userInfo = "yaga";
  final host = "cloud.test.com";
  final userDomain = "$userInfo@$host";
  final command = MockCommand<Preference, Preference>();
  final externalAppDirUri = Uri(host: "local", path: "/external/app/dir");
  final tmpAppDirUri = Uri(host: "local", path: "/internal/app/dir");
  final localPath = "/some/local/path";

  MappingManager uut;

  setUp(() async {
    when(settingsManagerBaseMock.updateSettingCommand)
        .thenAnswer((_) => command);

    when(nextCloudServiceMock.getOrigin()).thenReturn(ncRoot);
    when(nextCloudServiceMock.getUserDomain()).thenReturn(userDomain);

    when(systemLocationServiceMock.externalAppDirUri)
        .thenReturn(externalAppDirUri);
    when(systemLocationServiceMock.tmpAppDirUri).thenReturn(tmpAppDirUri);

    uut = MappingManager(
      settingsManagerBaseMock,
      nextCloudServiceMock,
      systemLocationServiceMock,
    );
  });

  void setUpMapping(String localPath, String remotePath) {
    MappingPreference pref = MappingPreference((b) => b
      ..key = "testKey"
      ..title = "Root Mapping"
      ..value = false
      ..local.value = Uri(host: "local", path: localPath)
      ..remote.value = Uri(host: "remote", path: remotePath));

    uut.handleMappingUpdate(pref);
  }

  group("map to tmp path", () {
    void mapToTmpPathTest(String remotePath) async {
      await uut.mapToTmpUri(Uri(host: "remote", path: remotePath));

      expect(
          verify(systemLocationServiceMock.absoluteUriFromInternal(captureAny))
              .captured
              .single
              .path,
          "${tmpAppDirUri.path}/$userDomain$remotePath");
    }

    test("default mapps to cache dir", () async {
      String remote = "/test/1.png";
      mapToTmpPathTest(remote);
    });

    test("mappings do not influence tmp", () async {
      String remote = "/test/1.png";
      setUpMapping(localPath, "/");
      mapToTmpPathTest(remote);
    });
  });

  group("map to local path", () {
    void mapToLocalPathTest({
      @required String remotePath,
      String remoteTargetFolderPath,
      @required String expectedPath,
    }) async {
      if (remoteTargetFolderPath != null) {
        setUpMapping(localPath, remoteTargetFolderPath);
      }

      await uut.mapToLocalUri(Uri(host: "remote", path: remotePath));

      expect(
          verify(systemLocationServiceMock.absoluteUriFromInternal(captureAny))
              .captured
              .single
              .path,
          expectedPath);
    }

    void mapRootToLocalPathTest(String remotePath) async {
      mapToLocalPathTest(
        remotePath: remotePath,
        remoteTargetFolderPath: "/",
        expectedPath: localPath + remotePath,
      );
    }

    void mapPicturesToLocalPathTest(String remotePath,
        {String expectedPath}) async {
      String targetPath = "/Pictures/";
      mapToLocalPathTest(
        remotePath: remotePath,
        remoteTargetFolderPath: targetPath,
        expectedPath: expectedPath ??
            localPath + remotePath.replaceFirst(targetPath, "/"),
      );
    }

    test("file with root mapping", () async {
      String remote = "/test/1.png";
      mapRootToLocalPathTest(remote);
    });

    test("dir with root mapping", () async {
      String remote = "/test/";
      mapRootToLocalPathTest(remote);
    });

    test("file with sub mapping", () async {
      String remote = "/Pictures/1.png";
      mapPicturesToLocalPathTest(remote);
    });

    test("dir with sub mapping", () async {
      String remote = "/Pictures/test/";
      mapPicturesToLocalPathTest(remote);
    });

    test("none sub mapping paths are mapped to app dir", () async {
      String remote = "/test/1.png";
      mapPicturesToLocalPathTest(remote,
          expectedPath: "${externalAppDirUri.path}/$userDomain$remote");
    });

    test("default mapps to app dir", () async {
      String remote = "/test/1.png";
      mapToLocalPathTest(
          remotePath: remote,
          expectedPath: "${externalAppDirUri.path}/$userDomain$remote");
    });
  });

  group("map tmp to remote uri", () {
    void mapTmpToRemoteUriTest(String relativePath) async {
      Uri tmp = Uri(
        host: "local",
        path: "${tmpAppDirUri.path}/$userDomain$relativePath",
      );
      Uri remote = Uri(
        scheme: "nc",
        userInfo: userInfo,
        host: host,
        pathSegments: [],
      );

      Uri result = await uut.mapTmpToRemoteUri(tmp, remote);

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
    void mapToRemoteUriTest({
      String localFilePath,
      String remotePath,
      String expectedPath,
      String mappingPath,
    }) async {
      Uri file = Uri(
        host: "local",
        path: localFilePath,
      );
      Uri remote = Uri(
        scheme: "nc",
        userInfo: userInfo,
        host: host,
        path: remotePath,
      );

      if (mappingPath != null) {
        setUpMapping(localPath, mappingPath);
      }

      Uri result = await uut.mapToRemoteUri(file, remote);

      expect(result.scheme, "nc");
      expect(result.userInfo, userInfo);
      expect(result.host, host);
      expect(result.path, expectedPath);
    }

    test("map file with default mapping", () async {
      mapToRemoteUriTest(
        localFilePath: "${externalAppDirUri.path}/$userDomain/test/1.png",
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
        localFilePath: "${externalAppDirUri.path}/$userDomain/test/1.png",
        remotePath: "/",
        expectedPath: "/test/1.png",
        mappingPath: "/Pictures/",
      );
    });
  });
}
