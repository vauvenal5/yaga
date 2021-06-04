import 'dart:io';
import 'dart:isolate';

import 'package:path_provider/path_provider.dart';
import 'package:yaga/model/system_location.dart';
import 'package:yaga/model/system_location_host.dart';
import 'package:yaga/services/service.dart';
import 'package:yaga/utils/forground_worker/isolateable.dart';
import 'package:yaga/utils/forground_worker/messages/init_msg.dart';
import 'package:yaga/utils/uri_utils.dart';

class SystemLocationService extends Service<SystemLocationService>
    implements Isolateable<SystemLocationService> {
  Map<String, SystemLocation> _locations = Map();
  List<SystemLocationHost> externals = [];

  @override
  Future<SystemLocationService> init() async {
    _init(
      await getExternalStorageDirectory(),
      await getTemporaryDirectory(),
      await getExternalStorageDirectories(),
    );
    return this;
  }

  @override
  Future<SystemLocationService> initIsolated(
    InitMsg init,
    SendPort isolateToMain,
  ) async {
    _init(init.externalPath, init.tmpPath, []);
    return this;
  }

  void _init(
      Directory externalDir, Directory tmpDir, List<Directory> external) {
    _locations[SystemLocationHost.local.name] = SystemLocation.fromSplitter(
        externalDir, SystemLocationHost.local, "/Android");
    _locations[SystemLocationHost.tmp.name] =
        SystemLocation.fromSplitter(tmpDir, SystemLocationHost.tmp, "/cache");
    external
        .where((element) => element.toString() != externalDir.toString())
        .forEach((element) {
      SystemLocationHost host =
          SystemLocationHost.sd(element.uri.pathSegments[1]);
      externals.add(host);
      _locations[host.name] =
          SystemLocation.fromSplitter(element, host, "/Android");
    });
  }

  Uri getOrigin({SystemLocationHost host = SystemLocationHost.local}) {
    SystemLocation location = _locations[host.name];
    return Uri(
      scheme: location.directory.uri.scheme,
      host: host.name,
      path: "/",
    );
  }

  //todo: think about this -> there are two ways of solving this
  //todo: first, we can infer the host by matching the starting part of the URI, advantage: self-contained, disadvantage: will require checking for every file
  //todo: second, we can require passing the host from the calling manager which should know if we are dealing with a local or tmp file
  Uri internalUriFromAbsolute(Uri absolute, {SystemLocationHost host}) {
    if (host != null) {
      SystemLocation loc = getLocation(host);
      if (absolute.path.startsWith(loc.privatePath)) {
        return Uri(
          scheme: absolute.scheme,
          host: host.name,
          path: _internalUriNormalizePath(absolute, loc),
        );
      }
      throw ArgumentError("Unknown system location!");
    }

    Uri res;

    _locations.forEach((key, value) {
      if (absolute.path.startsWith(value.privatePath)) {
        res = Uri(
          scheme: absolute.scheme,
          host: key,
          path: _internalUriNormalizePath(absolute, value),
        );
      }
    });

    if (res == null) {
      throw ArgumentError("Unknown system location!");
    }

    return res;
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
    return UriUtils.fromPathList(
      uri: _locations[internal.host].directory.uri,
      paths: [
        _locations[internal.host].privatePath,
        internal.path,
      ],
    );
  }

  //todo: can we make this const?
  Uri get externalAppDirUri => UriUtils.fromUri(
      uri: getOrigin(), path: getLocation(SystemLocationHost.local).publicPath);
  Uri get tmpAppDirUri => UriUtils.fromUri(
      uri: getOrigin(host: SystemLocationHost.tmp),
      path: getLocation(SystemLocationHost.tmp).publicPath);

  SystemLocation getLocation(SystemLocationHost host) {
    return this._locations[host.name];
  }
}
