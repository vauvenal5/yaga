import 'package:flutter/material.dart';
import 'package:yaga/model/preferences/preference.dart';
import 'package:yaga/model/preferences/section_preference.dart';
import 'package:yaga/model/preferences/uri_preference.dart';

class GeneralViewConfig {
  final SectionPreference general;
  final UriPreference path;

  @protected
  GeneralViewConfig.internal(this.general, this.path);

  factory GeneralViewConfig(String pref, Uri defaultPath, bool pathEnabled) {
    SectionPreference general = SectionPreference((b) => b
      ..key = Preference.prefixKey(pref, "general")
      ..title = "General");
    UriPreference path = UriPreference((b) => b
      ..key = general.prepareKey("path")
      ..title = "Path"
      ..value = defaultPath
      ..enabled = pathEnabled);

    return GeneralViewConfig.internal(general, path);
  }
}
