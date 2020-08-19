import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:nextcloud/nextcloud.dart';
import 'package:string_validator/string_validator.dart';
import 'package:yaga/model/nc_file.dart';
import 'package:yaga/services/nextcloud_service.dart';
import 'package:yaga/utils/nextcloud_client_factory.dart';

class NextCloudClientFactoryMock extends Mock implements NextCloudClientFactory {}
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

  group("NextCloudService", () {
    setUp(() async {
      factoryMock = NextCloudClientFactoryMock();
      clientMock = NextCloudClientMock();
      webDavClientMock = WebDavClientMock();
      avatarClientMock = AvatarClientMock();
      previewClientMock = PreviewClientMock();

      host = Uri(host: "cloud.test.com", scheme: "https");

      when(factoryMock.createNextCloudClient(host.toString(), "test", "password"))
        .thenAnswer((_) => clientMock);
      when(clientMock.webDav).thenAnswer((_) => webDavClientMock);
      when(clientMock.avatar).thenAnswer((_) => avatarClientMock);
      when(clientMock.preview).thenAnswer((_) => previewClientMock);
    });

    test("verify isLoggedIn after login and after logout", () {
      NextCloudService service = NextCloudService(factoryMock);
      
      expect(service.isLoggedIn(), false);

      service.login(host, "test", "password");

      expect(service.isLoggedIn(), true);

      service.logout();

      expect(service.isLoggedIn(), false);
    });

    group("list", () {
      bool _verifyNcFile(NcFile actual, WebDavFile expected) {
        expect(actual.name, expected.name);
        expect(actual.uri, Uri(scheme: "nc", host: host.host, userInfo: "test", path: expected.path));
        expect(actual.isDirectory, expected.isDirectory);
        expect(actual.lastModified, expected.lastModified);
        expect(actual.localFile, null);
        expect(actual.previewFile, null);
        return true;
      }

      test("list files and folders", () {
        NextCloudService service = NextCloudService(factoryMock);
        service.login(host, "test", "password");
        Uri uri = Uri(path: "/path");
        String remotePath = "files/test${uri.path}";

        when(clientMock.username).thenAnswer((_) => "test");

        List<WebDavFile> webDavFiles = [
          WebDavFile("/path/file.jpeg", "image/jpeg", 512, DateTime(2020)),
          WebDavFile("/path/file2.jpeg", "image/jpeg", 512, DateTime(2020)),
          WebDavFile("/path/path2/", "", 512, DateTime(2020))
        ];
        
        when(webDavClientMock.ls(remotePath)).thenAnswer((_) => Future.value(webDavFiles));

        expect(service.list(uri), emitsInOrder([
          (NcFile actual) => _verifyNcFile(actual, webDavFiles[0]),
          (NcFile actual) => _verifyNcFile(actual, webDavFiles[1]),
          (NcFile actual) => _verifyNcFile(actual, webDavFiles[2]),
          emitsDone
        ]));
      });

      test("filter wrong mime types", () {
        NextCloudService service = NextCloudService(factoryMock);
        service.login(host, "test", "password");
        Uri uri = Uri(path: "/path");
        String remotePath = "files/test${uri.path}";

        when(clientMock.username).thenAnswer((_) => "test");

        List<WebDavFile> webDavFiles = [
          WebDavFile("/path/file.html", "text/html", 512, DateTime(2020)),
          WebDavFile("/path/file.jpeg", "image/jpeg", 512, DateTime(2020)),
        ];
        
        when(webDavClientMock.ls(remotePath)).thenAnswer((_) => Future.value(webDavFiles));

        expect(service.list(uri), emitsInOrder([
          (NcFile actual) => _verifyNcFile(actual, webDavFiles[1]),
          emitsDone
        ]));
      });
    });

    test("check origin", () {
      NextCloudService service = NextCloudService(factoryMock);
      service.login(host, "test", "password");

      when(clientMock.username).thenAnswer((_) => "test");

      expect(service.getOrigin(), Uri(scheme: "nc", host: host.host, userInfo: "test", path: "/"));
    });

    group("isUriOfService", () {
      test("nextcloud uri", () {
        NextCloudService service = NextCloudService(factoryMock);
        expect(service.isUriOfService(Uri(scheme: "nc")), true);
      });

      test("local uri", () {
        NextCloudService service = NextCloudService(factoryMock);
        expect(service.isUriOfService(Uri(scheme: "file")), false);
      });
    });

    test("decode avatar", () async {
      NextCloudService service = NextCloudService(factoryMock);
      String value = "testing";
      service.login(host, "test", "password");

      when(clientMock.username).thenAnswer((_) => "test");
      when(avatarClientMock.getAvatar("test", 100)).thenAnswer((_) async => base64.encode(utf8.encode(value)));

      expect(String.fromCharCodes(await service.getAvatar()), value);
    });

    test("decodes preview path before request", () {
      NextCloudService service = NextCloudService(factoryMock);
      service.login(host, "test", "password");
      String file = "[test]-file.png";

      when(previewClientMock.getPreview(file, 128, 128)).thenAnswer((_) => Future.value(Uint8List(5)));

      service.getPreview(Uri(path: file));

      verify(previewClientMock.getPreview(file, 128, 128)).called(1);
    });

    test("download image path gets adapted", () {
      NextCloudService service = NextCloudService(factoryMock);
      service.login(host, "test", "password");
      when(clientMock.username).thenAnswer((_) => "test");

      Uri file = Uri(path: "/path/[test]-file.png");

      service.downloadImage(file);

      verify(webDavClientMock.download("files/test"+file.path)).called(1);
    });
  });
}