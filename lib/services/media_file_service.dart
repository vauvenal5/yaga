import 'dart:io';

import 'package:photo_manager/photo_manager.dart';
import 'package:rxdart/rxdart.dart';
import 'package:yaga/model/local_file.dart';
import 'package:yaga/model/nc_file.dart';
import 'package:yaga/services/isolateable/system_location_service.dart';
import 'package:yaga/services/service.dart';
import 'package:yaga/services/uri_name_resolver.dart';
import 'package:yaga/utils/ncfile_stream_extensions.dart';
import 'package:yaga/utils/uri_utils.dart';

class MediaFileService extends Service<MediaFileService> implements UriNameResolver {

  final SystemLocationService _systemLocationService;

  Map<String, AssetPathEntity> albums = {};

  MediaFileService(this._systemLocationService);

  Stream<NcFile> listFiles(Uri uri) {
    if(uri.path == "/") {
      return _fetchAlbums(uri);
    }

    //todo: this is a POC state; clean everything up!
    if(albums.containsKey(getNameFromUri(uri))) {
      return _fetchAlbum(uri);
    }

    return _fetchAlbums(getRootFromUri(uri))
        .collectToList()
        .flatMap((value) => _fetchAlbum(uri));
  }

  Stream<NcFile> _fetchAlbums(Uri uri) {
    return PhotoManager.getAssetPathList(type: RequestType.image).asStream()
        .doOnData((event) => albums = {})
        .flatMap((value) => Stream.fromIterable(value))
        .doOnData((event) => albums.putIfAbsent(event.id, () => event))
        .map((event) =>
        NcFile.directory(
            fromUri(uri: uri, path: "/${event.id}"),
            event.name),);
  }

  Stream<NcFile> _fetchAlbum(Uri uri) {
    return albums[getNameFromUri(uri)]!.getAssetListPaged(page: 0, size: 100).asStream()
        .flatMap((files) => Stream.fromIterable(files))
        .asyncMap((event) async {
      var file = NcFile.file(fromUri(uri: uri, path: "${event.relativePath}${event.title!}"), event.title!, event.mimeType);
      file.lastModified = event.modifiedDateTime;
      file.localFile = await _createLocalFile(file.uri);
      return file;
    });
  }

  Future<LocalFile> _createLocalFile(Uri uri) async {
    Uri internal = _systemLocationService.absoluteUriFromInternal(uri);
    File file = File.fromUri(internal);
    return LocalFile(file, file.existsSync());
  }

  @override
  Uri getHumanReadableForm(Uri uri) {
    var id = getNameFromUri(uri);

    if(albums.containsKey(id)) {
      return fromUri(uri: uri, path: "/${albums[id]!.name}");
    }

    return uri;
  }

  @override
  String get scheme => _systemLocationService.internalStorage.origin.scheme;

}