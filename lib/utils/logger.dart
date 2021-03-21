import 'dart:async';
import 'dart:io';
import 'package:logger/logger.dart';
import 'package:share/share.dart';
import 'package:yaga/utils/log_error_file_handler.dart';
import 'package:yaga/utils/forground_worker/foreground_worker.dart';
import 'package:yaga/utils/forground_worker/messages/flush_logs_message.dart';
import 'package:yaga/utils/service_locator.dart';
import 'package:yaga/utils/uri_utils.dart';

class YagaLogger {
  static final _logUri =
      UriUtils.fromPathList(uri: Directory.systemTemp.uri, paths: [
    Directory.systemTemp.uri.path,
    "yaga.log.txt",
  ]);
  static final _isolateLogUri =
      UriUtils.fromPathList(uri: Directory.systemTemp.uri, paths: [
    Directory.systemTemp.uri.path,
    "yaga.isolate.log.txt",
  ]);

  static LogErrorFileHandler _fileHandler;
  static LogErrorFileHandler get fileHandler => YagaLogger._fileHandler;

  static Logger getLogger(Type className, {level: Level.warning}) {
    return _getLogger(
      className,
      MultiOutput([
        ConsoleOutput(),
        YagaLogger._fileHandler,
      ]),
      level: level,
    );
  }

  static Logger getEmergencyLogger(Type className, {level: Level.warning}) {
    return _getLogger(className, ConsoleOutput(), level: level);
  }

  static Logger _getLogger(Type className, LogOutput output,
      {level: Level.warning}) {
    return Logger(
      printer: SimpleLogPrinter(className.toString()),
      output: output,
      level: level,
      filter: ProductionFilter(),
    );
  }

  static Future<void> init({bool isolate = false}) async {
    YagaLogger._fileHandler = LogErrorFileHandler(
      File.fromUri(isolate ? YagaLogger._isolateLogUri : YagaLogger._logUri),
      printLogs: true,
    );

    await YagaLogger._fileHandler.init();
  }

  static Future<void> printBaseLog() async {
    await YagaLogger._fileHandler.printDeviceInfo();
    await YagaLogger._fileHandler.printApplicationInfo();
  }

  static Future<void> shareLogs() async {
    StreamSubscription sub;
    sub = getIt
        .get<ForegroundWorker>()
        .isolateResponseCommand
        .where((msg) => msg is FlushLogsMessage && msg.flushed)
        .listen(
      (msg) async {
        try {
          await _fileHandler.flushFile();
          Share.shareFiles([
            YagaLogger._logUri.path,
            YagaLogger._isolateLogUri.path,
          ]);
        } finally {
          sub?.cancel();
        }
      },
      cancelOnError: true,
    );
    getIt.get<ForegroundWorker>().sendRequest(FlushLogsMessage());
  }
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

    var time = DateTime.now();

    if (event.level == Level.error) {
      return [
        color('$time $prefix $className - ${event.message}: ${event.error}'),
        color('Stacktrace: ${event?.stackTrace?.toString()}'),
      ];
    }

    return [color('$time $prefix $className - ${event.message}')];
  }
}
