import 'package:logger/logger.dart';

Logger getLogger(Type className, {level: Level.debug}) {
  return Logger(printer: SimpleLogPrinter(className.toString()), level: level);
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
    return [color('$prefix $className - ${event.message}')];
  }
}