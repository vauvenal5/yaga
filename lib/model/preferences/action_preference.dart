library preference;

import 'package:built_value/built_value.dart';
import 'package:yaga/model/preferences/preference.dart';

part 'action_preference.g.dart';

abstract class ActionPreference
    implements Preference, Built<ActionPreference, ActionPreferenceBuilder> {
  Function() get action;

  static void _initializeBuilder(ActionPreferenceBuilder b) =>
      Preference.initBuilder(b);

  factory ActionPreference([void Function(ActionPreferenceBuilder) updates]) =
      _$ActionPreference;
  ActionPreference._();
}
