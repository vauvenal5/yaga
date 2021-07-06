import 'package:yaga/model/nc_file.dart';
import 'package:rxdart/rxdart.dart';

extension NcFileStreamExtensions on Stream<NcFile> {
  Stream<List<NcFile>> collectToList() {
    return toList().asStream().onErrorReturn([]);
  }

  Stream<NcFile> recursively(Stream<NcFile> Function(Uri) listFilesFromUpstream,
      {bool recursive}) {
    return flatMap(
      (file) => Rx.merge([
        Stream.value(file),
        Stream.value(file)
            .where((file) => file.isDirectory)
            .where((_) => recursive)
            .flatMap(
              (file) => listFilesFromUpstream(
                file.uri,
              ).recursively(
                listFilesFromUpstream,
                recursive: recursive,
              ),
            )
      ]),
    );
  }
}
