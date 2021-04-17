import 'dart:io';
import 'dart:isolate';

import 'package:yaga/model/nc_login_data.dart';
import 'package:yaga/model/preferences/bool_preference.dart';
import 'package:yaga/model/preferences/mapping_preference.dart';

class InitMsg {
  final SendPort sendPort;
  final Directory externalPath;
  final Directory tmpPath;
  final NextCloudLoginData lastLoginData;
  final MappingPreference mapping;
  final String fingerprint;
  final BoolPreference autoPersist;

  InitMsg(
    this.sendPort,
    this.externalPath,
    this.tmpPath,
    this.lastLoginData,
    this.mapping,
    this.fingerprint,
    this.autoPersist,
  );
}
