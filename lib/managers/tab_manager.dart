import 'package:rx_command/rx_command.dart';
import 'package:yaga/views/screens/yaga_home_screen.dart';

class TabManager {
  RxCommand<YagaHomeTab, YagaHomeTab> tabChangedCommand =
      RxCommand.createSync((param) => param);
}
