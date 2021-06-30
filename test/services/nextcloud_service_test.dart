import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:nextcloud/nextcloud.dart';
import 'package:yaga/model/nc_file.dart';
import 'package:yaga/model/nc_login_data.dart';
import 'package:yaga/services/isolateable/nextcloud_service.dart';
import 'package:yaga/utils/nextcloud_client_factory.dart';

class NextCloudClientFactoryMock extends Mock
    implements NextCloudClientFactory {}

class NextCloudClientMock extends Mock implements NextCloudClient {}

class WebDavClientMock extends Mock implements WebDavClient {}

class AvatarClientMock extends Mock implements AvatarClient {}

class PreviewClientMock extends Mock implements PreviewClient {}

void main() {
  NextCloudClientFactoryMock factoryMock;
  NextCloudClientMock clientMock;
  WebDavClientMock webDavClientMock;
  AvatarClientMock avatarClientMock;
  PreviewClientMock previewClientMock;
  Uri host;
  NextCloudLoginData loginData;

  group("NextCloudService", () {
    setUp(() async {
      factoryMock = NextCloudClientFactoryMock();
      clientMock = NextCloudClientMock();
      webDavClientMock = WebDavClientMock();
      avatarClientMock = AvatarClientMock();
      previewClientMock = PreviewClientMock();

      host = Uri(host: "cloud.test.com", scheme: "https");
      loginData = NextCloudLoginData(host, "test", "password");

      when(factoryMock.createNextCloudClient(
              host, "test", "password"))
          .thenAnswer((_) => clientMock);
      when(clientMock.webDav).thenAnswer((_) => webDavClientMock);
      when(clientMock.avatar).thenAnswer((_) => avatarClientMock);
      when(clientMock.preview).thenAnswer((_) => previewClientMock);
    });

    test("verify isLoggedIn after login and after logout", () {
      final NextCloudService service = NextCloudService(factoryMock);

      expect(service.isLoggedIn(), false);

      service.login(loginData);

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

      test("list files and folders", () {
        final NextCloudService service = NextCloudService(factoryMock);
        service.login(loginData);
        final Uri uri = Uri(path: "/path");
        final String remotePath = "files/test${uri.path}";

        when(clientMock.username).thenAnswer((_) => "test");

        final List<WebDavFile> webDavFiles = [
          // WebDavFile("/path/file.jpeg", "image/jpeg", 512, DateTime(2020)),
          // WebDavFile("/path/file2.jpeg", "image/jpeg", 512, DateTime(2020)),
          // WebDavFile("/path/path2/", "", 512, DateTime(2020))
          WebDavFile("/path/file.jpeg"),
          WebDavFile("/path/file2.jpeg"),
          WebDavFile("/path/path2/")
        ];

        when(webDavClientMock.ls(remotePath))
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

      test("filter wrong mime types", () {
        final NextCloudService service = NextCloudService(factoryMock);
        service.login(loginData);
        final Uri uri = Uri(path: "/path");
        final String remotePath = "files/test${uri.path}";

        when(clientMock.username).thenAnswer((_) => "test");

        final List<WebDavFile> webDavFiles = [
          // WebDavFile("/path/file.html", "text/html", 512, DateTime(2020)),
          // WebDavFile("/path/file.jpeg", "image/jpeg", 512, DateTime(2020)),
          WebDavFile("/path/file.html"),
          WebDavFile("/path/file.jpeg"),
        ];

        when(webDavClientMock.ls(remotePath))
            .thenAnswer((_) => Future.value(webDavFiles));

        expect(
            service.list(uri),
            emitsInOrder([
              (NcFile actual) => _verifyNcFile(actual, webDavFiles[1]),
              emitsDone
            ]));
      });
    });

    test("check origin", () {
      final NextCloudService service = NextCloudService(factoryMock);
      service.login(loginData);

      when(clientMock.username).thenAnswer((_) => "test");

      expect(service.origin,
          Uri(scheme: "nc", host: host.host, userInfo: "test", path: "/"));
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
      service.login(loginData);

      when(clientMock.username).thenAnswer((_) => "test");
      when(avatarClientMock.getAvatar("test", 100))
          .thenAnswer((_) async => base64.encode(utf8.encode(value)));

      expect(String.fromCharCodes(await service.getAvatar()), value);
    });

    test("decodes preview path before request", () {
      final NextCloudService service = NextCloudService(factoryMock);
      service.login(loginData);
      const String file = "[test]-file.png";

      when(previewClientMock.getPreviewByPath(file, 128, 128))
          .thenAnswer((_) => Future.value(Uint8List(5)));

      service.getPreview(Uri(path: file));

      verify(previewClientMock.getPreviewByPath(file, 128, 128)).called(1);
    });

    test("download image path gets adapted", () {
      final NextCloudService service = NextCloudService(factoryMock);
      service.login(loginData);
      when(clientMock.username).thenAnswer((_) => "test");

      final Uri file = Uri(path: "/path/[test]-file.png");

      service.downloadImage(file);

      verify(webDavClientMock.download("files/test${file.path}")).called(1);
    });
  });
}
