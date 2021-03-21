import 'package:yaga/utils/forground_worker/messages/message.dart';

class FlushLogsMessage extends Message {
  final bool flushed;
  FlushLogsMessage({this.flushed = false}) : super("flush-log");
}
