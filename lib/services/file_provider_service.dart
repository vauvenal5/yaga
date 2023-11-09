import 'package:yaga/model/nc_file.dart';
import 'package:yaga/services/service.dart';

abstract class FileProviderService<T extends FileProviderService<T>>
    extends Service<T> {
  Stream<NcFile> list(Uri dir, bool favorites) => const Stream.empty();
}
