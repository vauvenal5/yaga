import 'package:flutter_test/flutter_test.dart';
import 'package:yaga/utils/uri_utils.dart';

void main() {
  group("fromUri", () {
    final Uri originalUri = Uri(
      scheme: "https",
      userInfo: "user",
      host: "cloud.nextcloud.com",
      port: 8443,
      path: "/original/path",
    );

    test("should override nothing", () {
      expect(
        fromUri(uri: originalUri).toString(),
        originalUri.toString(),
      );
    });

    test("should override everything", () {
      final Uri expected = Uri(
        scheme: "http",
        userInfo: "user2",
        host: "cloud.nc.com",
        port: 443,
        path: "/other/path",
      );

      expect(
        fromUri(
          uri: originalUri,
          scheme: expected.scheme,
          userInfo: expected.userInfo,
          host: expected.host,
          port: expected.port,
          path: expected.path,
        ).toString(),
        expected.toString(),
      );
    });
  });
  group("fromPathSegments", () {
    final Uri uri = Uri(host: "cloud.nextcloud.com", path: "/original/path");

    test("should ignore original uri path", () {
      const String firstPath = "/first/part";
      const String secondPath = "/second/part/";

      final Uri actual = fromPathList(
        uri: uri,
        paths: [firstPath, secondPath],
      );

      expect(actual.host, uri.host);
      expect(actual.path, "$firstPath$secondPath");
    });

    test("should not double encode special chars", () {
      const String firstPath = "/first/part/with%2Fspecial%2Fchar";
      const String secondPath = "/second/part/";

      final Uri actual = fromPathList(
        uri: uri,
        paths: [firstPath, secondPath],
      );

      expect(actual.host, uri.host);
      expect(actual.path, "$firstPath$secondPath");
    });
  });

  group("chainPathSegments", () {
    const String expected = "/first/part/second/part/";
    test("should correctly unite path with leading and trailing slash", () {
      const String first = "/first/part/";
      const String second = "/second/part/";
      expect(chainPathSegments(first, second), expected);
    });

    test("should correctly unite path with leading slash", () {
      const String first = "/first/part";
      const String second = "/second/part/";
      expect(chainPathSegments(first, second), expected);
    });

    test("should correctly unite path with trailing slash", () {
      const String first = "/first/part/";
      const String second = "second/part/";
      expect(chainPathSegments(first, second), expected);
    });

    test("should correctly unite path without slash", () {
      const  String first = "/first/part";
      const  String second = "second/part/";
      expect(chainPathSegments(first, second), expected);
    });
  });

  group("getRootFromUri", () {
    test("should return root uri from current uri", () {
      final Uri uri = Uri(host: "cloud.nextcloud.com", path: "/some/path");
      final Uri actual = getRootFromUri(uri);
      expect(actual.host, uri.host);
      expect(actual.path, "/");
    });
  });

  group("fromUriPathSegments", () {
    test("should not change meaning of special chars", () {
      const String expectedPath = "/test/path%2Fwith%2Fspecial/";
      final Uri uri = Uri(path: "${expectedPath}chars");
      expect(fromUriPathSegments(uri, 1).path, expectedPath);
    });

    test("should not change meaning of double encoded chars", () {
      const String expectedPath = "/test/path%252Fwith%252Fspecial/t%C3%B6st/";
      final Uri uri = Uri(path: "${expectedPath}chars");
      expect(fromUriPathSegments(uri, 2).path, expectedPath);
    });
  });

  group("getNameFromUri", () {
    test("should return file name from uri", () {
      const String fileName = "file.png";
      final Uri fileUri = Uri(pathSegments: ["test", "path", "to", fileName]);

      expect(getNameFromUri(fileUri), fileName);
    });

    test("should return folder name from uri", () {
      const String folder = "folder";
      final Uri folderUri = Uri(pathSegments: ["test", "path", "to", folder, ""]);

      expect(getNameFromUri(folderUri), folder);
    });

    test("should return host name from empty uri", () {
      const String host = "testHost";
      final Uri emptyUri = Uri(host: host);

      expect(getNameFromUri(emptyUri), host.toLowerCase());
    });
  });
}
