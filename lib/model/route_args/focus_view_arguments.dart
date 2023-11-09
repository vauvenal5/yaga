import 'package:yaga/views/screens/yaga_home_screen.dart';

class FocusViewArguments {
  final Uri path;
  final bool favorites;
  final YagaHomeTab selected;
  final String prefPrefix;

  FocusViewArguments(this.path, this.favorites, this.selected, this.prefPrefix);
}
