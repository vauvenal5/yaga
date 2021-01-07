import 'package:logger/logger.dart';

Logger getLogger(Type className, {level: Level.debug}) {
  ProductionFilter filter = ProductionFilter();
  filter.level = Level.warning;

  return Logger(
    printer: SimpleLogPrinter(className.toString()),
    level: level,
    filter: filter,
  );
}

class SimpleLogPrinter extends LogPrinter {
  final String className;
  SimpleLogPrinter(this.className);

  static final levelPrefixes = {
    Level.verbose: '[V]',
    Level.debug: '[D]',
    Level.info: '[I]',
    Level.warning: '[W]',
    Level.error: '[E]',
    Level.wtf: '[WTF]',
  };

  @override
  List<String> log(LogEvent event) {
    var color = PrettyPrinter.levelColors[event.level];
    var prefix = levelPrefixes[event.level];

    if (event.level == Level.error) {
      return [
        color('$prefix $className - ${event.message}: ${event.error}'),
        event.stackTrace.toString()
      ];
    }

    return [color('$prefix $className - ${event.message}')];
  }
}
