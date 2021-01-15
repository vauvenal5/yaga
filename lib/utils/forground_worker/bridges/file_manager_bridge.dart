import 'package:yaga/managers/file_manager.dart';
import 'package:yaga/utils/forground_worker/foreground_worker.dart';
import 'package:yaga/utils/forground_worker/messages/image_update_msg.dart';

class FileManagerBridge {
  final FileManager _fileManager;
  final ForegroundWorker _worker;

  FileManagerBridge(this._fileManager, this._worker) {
    this
        ._worker
        .isolateResponseCommand
        .where((event) => event is ImageUpdateMsg)
        .map((event) => event as ImageUpdateMsg)
        .listen((msg) => _fileManager.updateImageCommand(msg.file));
  }
}
