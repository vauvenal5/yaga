import 'dart:io';
import 'dart:isolate';

import 'package:yaga/model/nc_login_data.dart';
import 'package:yaga/model/preferences/bool_preference.dart';
import 'package:yaga/model/preferences/mapping_preference.dart';
import 'package:yaga/utils/background_worker/messages/background_init_msg.dart';

class InitMsg extends BackgroundInitMsg {
  final SendPort sendPort;
  final Directory externalPath;
  final Directory tmpPath;
  final List<Directory> externalPaths;
  final MappingPreference? mapping;
  final BoolPreference autoPersist;

  InitMsg(
    this.sendPort,
    this.externalPath,
    this.tmpPath,
    this.externalPaths,
    NextCloudLoginData lastLoginData,
    this.mapping,
    String fingerprint,
    this.autoPersist,
  ): super(lastLoginData, fingerprint);
}
