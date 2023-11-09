import 'package:yaga/model/nc_file.dart';
import 'package:rxdart/rxdart.dart';

extension NcFileStreamExtensions on Stream<NcFile> {
  Stream<List<NcFile>> collectToList() {
    return toList().asStream().onErrorReturn([]);
  }

  Stream<NcFile> recursively(Stream<NcFile> Function(Uri, {bool favorites}) listFilesFromUpstream,
      {required bool recursive, bool favorites = false}) {
    return flatMap(
      (file) => Rx.merge([
        Stream.value(file),
        Stream.value(file)
            .where((file) => file.isDirectory)
            .where((_) => recursive)
            .flatMap(
              (file) => listFilesFromUpstream(
                file.uri,
                favorites: favorites,
              ).recursively(
                listFilesFromUpstream,
                recursive: recursive,
                favorites: favorites,
              ),
            )
      ]),
    );
  }
}
