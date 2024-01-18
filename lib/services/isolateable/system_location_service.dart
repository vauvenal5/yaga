import 'dart:io';
import 'dart:isolate';

import 'package:path_provider/path_provider.dart';
import 'package:yaga/model/system_location.dart';
import 'package:yaga/services/service.dart';
import 'package:yaga/utils/forground_worker/isolateable.dart';
import 'package:yaga/utils/forground_worker/messages/init_msg.dart';
import 'package:yaga/utils/uri_utils.dart';

class SystemLocationService extends Service<SystemLocationService>
    implements Isolateable<SystemLocationService> {
  static final _internalOrigin =
      Uri(scheme: "file", host: "device.local", path: "/");
  static final _tmpOrigin = Uri(scheme: "file", host: "device.tmp", path: "/");
  static const _externalHost = "device.ext";

  final Map<String, SystemLocation> _locations = {};

  List<SystemLocation> get externals => _locations.values
      .where((element) => element.origin != _internalOrigin)
      .where((element) => element.origin != _tmpOrigin)
      .toList();

  @override
  Future<SystemLocationService> init() async {
    _init(
      (await getExternal())!,
      await getCacheDir(),
      (await getExternals())!,
    );
    return this;
  }

  Future<Directory> getCacheDir() => getApplicationCacheDirectory();
  Future<Directory?> getExternal() => Platform.isAndroid ? getExternalStorageDirectory() : getApplicationSupportDirectory();
  Future<List<Directory>?> getExternals() async {
    if(Platform.isAndroid) {
      return getExternalStorageDirectories();
    }
    return [await getApplicationSupportDirectory()];
  }

  @override
  Future<SystemLocationService> initIsolated(
    InitMsg init,
    SendPort isolateToMain,
  ) async {
    _init(init.externalPath, init.tmpPath, init.externalPaths);
    return this;
  }

  void _init(
      Directory externalDir, Directory tmpDir, List<Directory> external) {
    _locations[_internalOrigin.authority] =
      Platform.isAndroid ?
        SystemLocation.fromSplitter(externalDir, _internalOrigin, "/Android") :
      SystemLocation(externalDir, _internalOrigin);
    _locations[_tmpOrigin.authority] =
      Platform.isAndroid ?
      SystemLocation.fromSplitter(tmpDir, _tmpOrigin, "/cache") :
      SystemLocation(tmpDir, _tmpOrigin);
    external
        .where((element) => element.toString() != externalDir.toString())
        .forEach((element) {
      final Uri origin = Uri(
        scheme: "file",
        userInfo: element.uri.pathSegments[1],
        host: _externalHost,
        path: "/",
      );
      _locations[origin.authority] = Platform.isAndroid ?
        SystemLocation.fromSplitter(element, origin, "/Android") :
        SystemLocation(element, origin);
    });
  }

  //todo: think about this -> there are two ways of solving this
  //todo: first, we can infer the host by matching the starting part of the URI, advantage: self-contained, disadvantage: will require checking for every file
  //todo: second, we can require passing the host from the calling manager which should know if we are dealing with a local or tmp file
  Uri internalUriFromAbsolute(Uri absolute) {
    Uri? res;

    _locations.forEach((key, value) {
      if (absolute.path.startsWith(value.privatePath)) {
        res = fromUri(
          uri: value.origin,
          path: _internalUriNormalizePath(absolute, value),
        );
      }
    });

    if (res == null) {
      throw ArgumentError("Unknown system location!");
    }

    return res!;
  }

  String _internalUriNormalizePath(Uri absolute, SystemLocation location) {
    return absolute.path.replaceFirst(location.privatePath, "");
  }

  Uri absoluteUriFromInternal(Uri internal) {
    // already absolute
    if (internal.host == "") {
      return internal;
    }
    //todo: add a test when a local folder contain uri encoded chars
    //--> this happens when a server is behind a subpath cloud.com/nc
    //--> then NC Files App will create a local folder like cloud.com%2Fnc
    return fromPathList(
      uri: _locations[internal.authority]!.absoluteUri,
      paths: [
        _locations[internal.authority]!.privatePath,
        internal.path,
      ],
    );
  }

  SystemLocation get internalStorage => _locations[_internalOrigin.authority]!;

  SystemLocation get internalCache => _locations[_tmpOrigin.authority]!;
}
