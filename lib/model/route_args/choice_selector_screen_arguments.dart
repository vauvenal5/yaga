import 'package:yaga/model/preferences/choice_preference.dart';

class ChoiceSelectorScreenArguments {
  final ChoicePreference choicePreference;
  final void Function() onCancel;
  final void Function(String) onSelect;

  ChoiceSelectorScreenArguments(
      this.choicePreference, this.onSelect, this.onCancel);
}
