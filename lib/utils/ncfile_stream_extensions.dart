import 'package:yaga/model/nc_file.dart';
import 'package:rxdart/rxdart.dart';

extension NcFileStreamExtensions on Stream<NcFile> {
  Stream<List<NcFile>> collectToList() {
    return this.toList().asStream().onErrorReturn([]);
  }

  Stream<NcFile> recursively(
    bool recursive,
    Stream<NcFile> Function(Uri) listFilesFromUpstream,
  ) {
    return this.flatMap(
      (file) => Rx.merge([
        Stream.value(file),
        Stream.value(file)
            .where((file) => file.isDirectory)
            .where((_) => recursive)
            .flatMap(
              (file) => listFilesFromUpstream(
                file.uri,
              ).recursively(
                recursive,
                listFilesFromUpstream,
              ),
            )
      ]),
    );
  }
}
