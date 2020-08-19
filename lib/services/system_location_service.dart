import 'package:path_provider/path_provider.dart';
import 'package:yaga/model/system_location.dart';
import 'package:yaga/model/system_location_host.dart';
import 'package:yaga/services/service.dart';
import 'package:yaga/utils/uri_utils.dart';
import 'package:string_validator/string_validator.dart';

class SystemLocationService extends Service<SystemLocationService> {
  Map<String, SystemLocation> _locations = Map();

  @override
  Future<SystemLocationService> init() async {
    _locations[SystemLocationHost.local.name] = SystemLocation.fromSplitter(await getExternalStorageDirectory(), SystemLocationHost.local, "/Android");
    _locations[SystemLocationHost.tmp.name] = SystemLocation.fromSplitter(await getTemporaryDirectory(), SystemLocationHost.tmp, "/cache");
    return this;
  }

  Uri getOrigin({SystemLocationHost host = SystemLocationHost.local}) {
    SystemLocation location = _locations[host.name];
    return Uri(scheme: location.directory.uri.scheme, host: host.name, path: "/");
  }

  //todo: think about this -> there are two ways of solving this
  //todo: first, we can infer the host by matching the starting part of the URI, advantage: self-contained, disadvantage: will require checking for every file
  //todo: second, we can require passing the host from the calling manager which should know if we are dealing with a local or tmp file
  Uri internalUriFromAbsolute(Uri absolute, {SystemLocationHost host}) {
    if(host != null) {
      SystemLocation loc = _getLocation(host);
      if(absolute.path.startsWith(loc.privatePath)) {
        return Uri(scheme: absolute.scheme, host: host.name, path: _internalUriNormalizePath(absolute, loc));
      }
      throw ArgumentError("Unknown system location!");
    }

    Uri res;
    
    _locations.forEach((key, value) {
      if(absolute.path.startsWith(value.privatePath)) {
        res = Uri(scheme: absolute.scheme, host: key, path: _internalUriNormalizePath(absolute, value));
      }
    });

    if(res == null) {
      throw ArgumentError("Unknown system location!");
    }

    return res;
  }

  String _internalUriNormalizePath(Uri absolute, SystemLocation location) {
    return absolute.path.replaceFirst(location.privatePath, "");
  }

  Uri absoluteUriFromInternal(Uri internal) {
    // already absolute
    if(internal.host == "") {
      return internal;
    }
    return Uri(scheme: internal.scheme, path: _locations[internal.host].privatePath+internal.path);
  }

  //todo: can we make this const?
  Uri get externalAppDirUri => UriUtils.fromUri(uri: getOrigin(), path: _getLocation(SystemLocationHost.local).publicPath);
  Uri get tmpAppDirUri => UriUtils.fromUri(uri: getOrigin(host: SystemLocationHost.tmp), path: _getLocation(SystemLocationHost.tmp).publicPath);

  SystemLocation _getLocation(SystemLocationHost host) {
    return this._locations[host.name];
  }
}