import 'dart:io';
import 'dart:isolate';

import 'package:yaga/model/nc_login_data.dart';

class InitMsg {
  final SendPort sendPort;
  final Directory externalPath;
  final Directory tmpPath;

  InitMsg(this.sendPort, this.externalPath, this.tmpPath);
}