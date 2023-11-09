import 'package:yaga/model/sort_config.dart';
import 'package:yaga/utils/forground_worker/messages/message.dart';

class FileListRequest extends Message {
  final Uri uri;
  final bool recursive;
  final bool favorites;
  final SortConfig config;

  FileListRequest(
    String key,
    this.uri,
    this.config, {
    this.recursive = false,
    this.favorites = false,
  }) : super(key);
}
