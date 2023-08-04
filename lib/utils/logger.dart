import 'dart:async';
import 'dart:io';
import 'package:ansicolor/ansicolor.dart';
import 'package:logging/logging.dart';
import 'package:share_plus/share_plus.dart';
import 'package:yaga/utils/log_error_file_handler.dart';
import 'package:yaga/utils/forground_worker/foreground_worker.dart';
import 'package:yaga/utils/forground_worker/messages/flush_logs_message.dart';
import 'package:yaga/utils/service_locator.dart';
import 'package:yaga/utils/uri_utils.dart';

class YagaLogger {
  const YagaLogger();

  static final _logUri = fromPathList(uri: Directory.systemTemp.uri, paths: [
    Directory.systemTemp.uri.path,
    "yaga.log.txt",
  ]);
  static final _isolateLogUri =
      fromPathList(uri: Directory.systemTemp.uri, paths: [
    Directory.systemTemp.uri.path,
    "yaga.isolate.log.txt",
  ]);

  static late LogErrorFileHandler _fileHandler;
  static LogErrorFileHandler get fileHandler => YagaLogger._fileHandler;

  static Logger getLogger(Type className) {
    return _getLogger(
      className,
    );
  }

  static Logger getEmergencyLogger(Type className) {
    return _getLogger(className);
  }

  static Logger _getLogger(Type className) {
    return Logger(className.toString());
  }

  static final levelColors = {
    Level.FINEST: AnsiPen()..xterm(8),
    Level.FINER: AnsiPen()..xterm(8),
    Level.FINE: AnsiPen()..xterm(8),
    Level.INFO: AnsiPen()..xterm(12),
    Level.WARNING: AnsiPen()..xterm(208),
    Level.SEVERE: AnsiPen()..xterm(196),
    Level.SHOUT: AnsiPen()..xterm(199),
  };

  static Future<void> init({bool isolate = false}) async {
    YagaLogger._fileHandler = LogErrorFileHandler(
      File.fromUri(isolate ? YagaLogger._isolateLogUri : YagaLogger._logUri),
      printLogs: true,
    );

    await YagaLogger._fileHandler.init();

    ansiColorDisabled = false;
    Logger.root.level = Level.INFO;
    Logger.root.onRecord.listen((record) {
      final List<String> logs = [
        '${record.time} ${record.level} ${record.loggerName} - ${record.message}',
      ];

      if (record.stackTrace != null) {
        logs.add(
          '${record.time} ${record.level} ${record.loggerName} - ${record.stackTrace}',
        );
      }

      for (final log in logs) {
        print(levelColors[record.level]!(log));
        YagaLogger._fileHandler.writeLineToFile(log);
      }
    });
  }

  static Future<void> printBaseLog() async {
    await YagaLogger._fileHandler.printDeviceInfo();
    await YagaLogger._fileHandler.printApplicationInfo();
  }

  static Future<void> shareLogs() async {
    StreamSubscription? sub;
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
