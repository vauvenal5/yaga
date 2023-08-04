import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:nextcloud/nextcloud.dart';
import 'package:yaga/model/nc_file.dart';
import 'package:yaga/model/nc_login_data.dart';
import 'package:yaga/services/isolateable/nextcloud_service.dart';
import 'package:yaga/utils/nextcloud_client_factory.dart';
import 'nextcloud_service_test.mocks.dart';

@GenerateMocks([NextCloudClientFactory, NextCloudClient, WebDavClient, AvatarClient, PreviewClient, UserClient])
void main() {
  final MockNextCloudClientFactory factoryMock = MockNextCloudClientFactory();
  final MockNextCloudClient clientMock = MockNextCloudClient();
  final MockWebDavClient webDavClientMock = MockWebDavClient();
  final MockAvatarClient avatarClientMock = MockAvatarClient();
  final MockPreviewClient previewClientMock = MockPreviewClient();
  final MockUserClient userClient = MockUserClient();
  final Uri host = Uri(host: "cloud.test.com", scheme: "https");
  final NextCloudLoginData loginData = NextCloudLoginData(host, "test", "password");
  final UserData userData = UserData("test", "test", "test@cloud.test.com", "storageLocation");

  group("NextCloudService", () {
    setUp(() async {
      // factoryMock = NextCloudClientFactoryMock();
      // clientMock = NextCloudClientMock();
      // webDavClientMock = WebDavClientMock();
      // avatarClientMock = AvatarClientMock();
      // previewClientMock = PreviewClientMock();

      // host = Uri(host: "cloud.test.com", scheme: "https");
      // loginData = NextCloudLoginData(host, "test", "password");

      when(factoryMock.createNextCloudClient(
              loginData.server!, loginData.user, loginData.password))
          .thenAnswer((_) => clientMock);
      when(clientMock.webDav).thenAnswer((_) => webDavClientMock);
      when(clientMock.avatar).thenAnswer((_) => avatarClientMock);
      when(clientMock.preview).thenAnswer((_) => previewClientMock);
      when(clientMock.user).thenReturn(userClient);
      when(userClient.getUser()).thenAnswer((_) => Future.value(userData));
    });

    WebDavFile createWebDavFile(String path, { String mime = "image/jpeg" }) =>
        WebDavFile(path)
          ..mimeType = mime
          ..lastModified = DateTime(2020);

    test("verify isLoggedIn after login and after logout", () async {
      final NextCloudService service = NextCloudService(factoryMock);

      expect(service.isLoggedIn(), false);

      await service.login(loginData);

      expect(service.isLoggedIn(), true);

      service.logout();

      expect(service.isLoggedIn(), false);
    });

    group("list", () {
      bool _verifyNcFile(NcFile actual, WebDavFile expected) {
        expect(actual.name, expected.name);
        expect(
            actual.uri,
            Uri(
                scheme: "nc",
                host: host.host,
                userInfo: "test",
                path: expected.path));
        expect(actual.isDirectory, expected.isDirectory);
        expect(actual.lastModified, expected.lastModified);
        expect(actual.localFile, null);
        expect(actual.previewFile, null);
        return true;
      }

      test("list files and folders", () async {
        final NextCloudService service = NextCloudService(factoryMock);
        await service.login(loginData);
        final Uri uri = Uri(path: "/path");
        final String remotePath = "files/test${uri.path}";

        //when(clientMock.user).thenAnswer((_) => "test");

        final List<WebDavFile> webDavFiles = [
          // WebDavFile("/path/file.jpeg", "image/jpeg", 512, DateTime(2020)),
          // WebDavFile("/path/file2.jpeg", "image/jpeg", 512, DateTime(2020)),
          // WebDavFile("/path/path2/", "", 512, DateTime(2020))
          createWebDavFile("/path/file.jpeg"),
          createWebDavFile("/path/file2.jpeg"),
          createWebDavFile("/path/path2/", mime: "")
        ];

        when(webDavClientMock.ls(uri.path))
            .thenAnswer((_) => Future.value(webDavFiles));

        expect(
            service.list(uri),
            emitsInOrder([
              (NcFile actual) => _verifyNcFile(actual, webDavFiles[0]),
              (NcFile actual) => _verifyNcFile(actual, webDavFiles[1]),
              (NcFile actual) => _verifyNcFile(actual, webDavFiles[2]),
              emitsDone
            ]));
      });

      test("filter wrong mime types", () async {
        final NextCloudService service = NextCloudService(factoryMock);
        await service.login(loginData);
        final Uri uri = Uri(path: "/path");
        final String remotePath = "files/test${uri.path}";

        // when(clientMock.username).thenAnswer((_) => "test");

        final List<WebDavFile> webDavFiles = [
          // WebDavFile("/path/file.html", "text/html", 512, DateTime(2020)),
          // WebDavFile("/path/file.jpeg", "image/jpeg", 512, DateTime(2020)),
          createWebDavFile("/path/file.html", mime: "text/html"),
          createWebDavFile("/path/file.jpeg"),
        ];

        when(webDavClientMock.ls(uri.path))
            .thenAnswer((_) => Future.value(webDavFiles));

        expect(
            service.list(uri),
            emitsInOrder([
              (NcFile actual) => _verifyNcFile(actual, webDavFiles[1]),
              emitsDone
            ]));
      });
    });

    test("check origin", () async {
      final NextCloudService service = NextCloudService(factoryMock);
      await service.login(loginData);

      // when(clientMock.username).thenAnswer((_) => "test");

      expect(service.origin!.uri, Uri(scheme: "nc", host: host.host, port: 443));
      expect(service.origin!.username, "test");
    });

    group("isUriOfService", () {
      test("nextcloud uri", () {
        final NextCloudService service = NextCloudService(factoryMock);
        expect(service.isUriOfService(Uri(scheme: "nc")), true);
      });

      test("local uri", () {
        final NextCloudService service = NextCloudService(factoryMock);
        expect(service.isUriOfService(Uri(scheme: "file")), false);
      });
    });

    test("decode avatar", () async {
      final NextCloudService service = NextCloudService(factoryMock);
      const String value = "testing";
      await service.login(loginData);

      // when(clientMock.username).thenAnswer((_) => "test");
      when(avatarClientMock.getAvatar("test", 100))
          .thenAnswer((_) async => base64.encode(utf8.encode(value)));

      expect(String.fromCharCodes(await service.getAvatar()), value);
    });

    test("decodes preview path before request", () async {
      final NextCloudService service = NextCloudService(factoryMock);
      await service.login(loginData);
      const String file = "[test]-file.png";

      when(previewClientMock.getPreviewByPath(file, 128, 128))
          .thenAnswer((_) => Future.value(Uint8List(5)));

      service.getPreview(Uri(path: file));

      verify(previewClientMock.getPreviewByPath(file, 128, 128)).called(1);
    });
  });
}
