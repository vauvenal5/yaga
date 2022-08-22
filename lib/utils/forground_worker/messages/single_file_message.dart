import 'package:yaga/model/nc_file.dart';
import 'package:yaga/utils/background_worker/json_convertable.dart';

abstract class SingleFileMessage extends JsonConvertable {
  static const String _jsonFile = "file";

  final NcFile file;

  SingleFileMessage(String key, String type, this.file) : super(key, type);

  SingleFileMessage.fromJson(Map<String, dynamic> json)
      : file = NcFile.fromJson(json[_jsonFile] as Map<String, dynamic>),
        super.fromJson(json);

  @override
  Map<String, dynamic> toJson() {
    final superMap = super.toJson();
    superMap[_jsonFile] = file.toJson();
    return superMap;
  }
}
