import 'package:flutter_test/flutter_test.dart';
import 'package:yaga/utils/uri_utils.dart';

void main() {
  group("fromUri", () {
    Uri originalUri = Uri(
      scheme: "https",
      userInfo: "user",
      host: "cloud.nextcloud.com",
      port: 8443,
      path: "/original/path",
    );

    test("should override nothing", () {
      expect(
        UriUtils.fromUri(uri: originalUri).toString(),
        originalUri.toString(),
      );
    });

    test("should override everything", () {
      Uri expected = Uri(
        scheme: "http",
        userInfo: "user2",
        host: "cloud.nc.com",
        port: 443,
        path: "/other/path",
      );

      expect(
        UriUtils.fromUri(
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
    Uri uri = Uri(host: "cloud.nextcloud.com", path: "/original/path");

    test("should ignore original uri path", () {
      String firstPath = "/first/part";
      String secondPath = "/second/part/";

      Uri actual = UriUtils.fromPathList(
        uri: uri,
        paths: [firstPath, secondPath],
      );

      expect(actual.host, uri.host);
      expect(actual.path, "$firstPath$secondPath");
    });

    test("should not double encode special chars", () {
      String firstPath = "/first/part/with%2Fspecial%2Fchar";
      String secondPath = "/second/part/";

      Uri actual = UriUtils.fromPathList(
        uri: uri,
        paths: [firstPath, secondPath],
      );

      expect(actual.host, uri.host);
      expect(actual.path, "$firstPath$secondPath");
    });
  });

  group("chainPathSegments", () {
    String expected = "/first/part/second/part/";
    test("should correctly unite path with leading and trailing slash", () {
      String first = "/first/part/";
      String second = "/second/part/";
      expect(UriUtils.chainPathSegments(first, second), expected);
    });

    test("should correctly unite path with leading slash", () {
      String first = "/first/part";
      String second = "/second/part/";
      expect(UriUtils.chainPathSegments(first, second), expected);
    });

    test("should correctly unite path with trailing slash", () {
      String first = "/first/part/";
      String second = "second/part/";
      expect(UriUtils.chainPathSegments(first, second), expected);
    });

    test("should correctly unite path without slash", () {
      String first = "/first/part";
      String second = "second/part/";
      expect(UriUtils.chainPathSegments(first, second), expected);
    });
  });

  group("getRootFromUri", () {
    test("should return root uri from current uri", () {
      Uri uri = Uri(host: "cloud.nextcloud.com", path: "/some/path");
      Uri actual = UriUtils.getRootFromUri(uri);
      expect(actual.host, uri.host);
      expect(actual.path, "/");
    });
  });

  group("fromUriPathSegments", () {
    test("should not change meaning of special chars", () {
      String expectedPath = "/test/path%2Fwith%2Fspecial/";
      Uri uri = Uri(path: "${expectedPath}chars");
      expect(UriUtils.fromUriPathSegments(uri, 1).path, expectedPath);
    });
  });

  group("getNameFromUri", () {
    test("should return file name from uri", () {
      String fileName = "file.png";
      Uri fileUri = Uri(pathSegments: ["test", "path", "to", fileName]);

      expect(UriUtils.getNameFromUri(fileUri), fileName);
    });

    test("should return folder name from uri", () {
      String folder = "folder";
      Uri folderUri = Uri(pathSegments: ["test", "path", "to", folder, ""]);

      expect(UriUtils.getNameFromUri(folderUri), folder);
    });

    test("should return host name from empty uri", () {
      String host = "testHost";
      Uri emptyUri = Uri(host: host);

      expect(UriUtils.getNameFromUri(emptyUri), host.toLowerCase());
    });
  });
}
