import 'package:yaga/model/system_location.dart';

class SystemLocationHost {
  final String name;

  const SystemLocationHost._(this.name);

  static const SystemLocationHost local = SystemLocationHost._("device.local");
  static const SystemLocationHost tmp = SystemLocationHost._("device.tmp");
}