import 'package:neon_framework/neon.dart';
import 'apps.dart';
import 'branding.dart';

Future<void> main() async {
  await runNeon(
    appImplementations: appImplementations,
    theme: neonTheme,
  );
}
