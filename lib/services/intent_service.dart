import 'package:flutter/services.dart';
import 'package:mime/mime.dart';
import 'package:yaga/model/nc_file.dart';
import 'package:yaga/services/service.dart';

class IntentService extends Service<IntentService> {
  static const _intentChannel = MethodChannel('yaga.channel.intent');
  late String _intentAction;

  @override
  Future<IntentService> init() async {
    _intentAction = await getIntentAction();
    return this;
  }

  String getCachedIntentAction() => _intentAction;

  Future<String> getIntentAction() async {
    return _intentChannel
        .invokeMethod("getIntentAction")
        .then((value) => value.toString());
  }

  Future<bool> setSelectedFile(NcFile file) async {
    //todo: maybe we should keep the mime type in the NcFile object
    final String mime = lookupMimeType(file.localFile!.file.path)??'';
    return _intentChannel.invokeMethod("setSelectedFile", {
      "name": file.name,
      "path": file.localFile!.file.path,
      "mime": mime,
    }).then((value) => value as bool);
  }

  bool get isOpenForSelect =>
      _intentAction == "android.intent.action.GET_CONTENT" ||
      _intentAction == "android.intent.action.PICK";
}
