import 'package:yaga/utils/forground_worker/messages/message.dart';

abstract class JsonConvertable extends Message {
  static const String _jsonKey = "key";
  static const String jsonTypeField = "jsonType";

  final String jsonType;

  JsonConvertable(String key, this.jsonType) : super(key);

  JsonConvertable.fromJson(Map<String, dynamic> json)
      : jsonType = json[jsonTypeField] as String,
        super(json[_jsonKey] as String);

  Map<String, dynamic> toJson() {
    return {
      jsonTypeField: jsonType,
      _jsonKey: key,
    };
  }
}
