import 'dart:convert';
import 'dart:io';

import 'package:catcher/core/application_profile_manager.dart';
import 'package:catcher/model/platform_type.dart';
import 'package:catcher/model/report.dart';
import 'package:catcher/model/report_handler.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:yaga/utils/logger.dart';
import 'package:device_info_plus/device_info_plus.dart';

class LogErrorFileHandler extends ReportHandler {
  final File file;
  final bool enableDeviceParameters;
  final bool enableApplicationParameters;
  final bool enableStackTrace;
  final bool enableCustomParameters;
  final bool printLogs;

  //emergency logger for when errors occure in LogErrorFileHandler
  final _logger = YagaLogger.getEmergencyLogger(LogErrorFileHandler);

  IOSink? _sink;
  bool _fileValidationResult = false;

  LogErrorFileHandler(this.file,
      {this.enableDeviceParameters = false,
      this.enableApplicationParameters = false,
      this.enableStackTrace = true,
      this.enableCustomParameters = true,
      this.printLogs = false})
      : assert(file != null, "File can't be null"),
        assert(enableDeviceParameters != null,
            "enableDeviceParameters can't be null"),
        assert(enableApplicationParameters != null,
            "enableApplicationParameters can't be null"),
        assert(enableStackTrace != null, "enableStackTrace can't be null"),
        assert(enableCustomParameters != null,
            "enableCustomParameters can't be null"),
        assert(printLogs != null, "printLogs can't be null");

  @override
  Future<bool> handle(Report report, BuildContext? context) async {
    try {
      if (_sink == null) {
        await init();
      }
      return await _processReport(report);
    } catch (exc, stackTrace) {
      _logger.severe("Exception occured: $exc stack: $stackTrace");
      return false;
    }
  }

  Future<bool> _processReport(Report report) async {
    if (_fileValidationResult) {
      _writeReportToFile(report);
      return true;
    } else {
      return false;
    }
  }

  Future<bool> _checkFile() async {
    try {
      final bool exists = await file.exists();
      if (!exists) {
        file.createSync();
      }
      final IOSink sink = file.openWrite(mode: FileMode.append);
      sink.write("");
      await sink.flush();
      await sink.close();
      return true;
    } catch (exc, stackTrace) {
      _logger.severe("Exception occured: $exc stack: $stackTrace");
      return false;
    }
  }

  void _openFile() {
    if (_sink == null) {
      _sink = file.openWrite(mode: FileMode.writeOnly);
      _printLog("Opened file");
    }
  }

  void _writeLineToFile(String text) {
    _logger.shout(text);
  }

  void writeLineToFile(String text) {
    _sink?.add(utf8.encode('$text\n'));
  }

  Future flushFile() async => _sink?.flush();

  Future _closeFile() async {
    _printLog("Closing file");
    await _sink?.flush();
    await _sink?.close();
    _sink = null;
  }

  Future<void> _writeReportToFile(Report report) async {
    _printLog("Writing report to file");
    _writeLineToFile(
        "============================== CATCHER LOG ==============================");
    _writeLineToFile("Crash occured on ${report.dateTime}");
    _writeLineToFile("");
    if (enableDeviceParameters) {
      _logDeviceParametersFormatted(report.deviceParameters);
      _writeLineToFile("");
    }
    if (enableApplicationParameters) {
      _logApplicationParametersFormatted(report.applicationParameters);
      _writeLineToFile("");
    }
    _writeLineToFile("---------- ERROR ----------");
    _writeLineToFile("${report.error}");
    _writeLineToFile("");
    if (enableStackTrace) {
      _writeLineToFile("------- STACK TRACE -------");
      _writeLineToFile("${report.stackTrace}");
    }
    if (enableCustomParameters) {
      _logCustomParametersFormatted(report.customParameters);
    }
    _writeLineToFile(
        "======================================================================");
  }

  void _logDeviceParametersFormatted(Map<String, dynamic> deviceParameters) {
    _writeLineToFile("------- DEVICE INFO -------");
    for (final entry in deviceParameters.entries) {
      _writeLineToFile("${entry.key}: ${entry.value}");
    }
    _writeLineToFile("------- END DEVICE INFO -------");
  }

  void _logApplicationParametersFormatted(
      Map<String, dynamic> applicationParameters) {
    _writeLineToFile("------- APP INFO -------");
    for (final entry in applicationParameters.entries) {
      _writeLineToFile("${entry.key}: ${entry.value}");
    }
    _writeLineToFile("------- END APP INFO -------");
  }

  void _logCustomParametersFormatted(Map<String, dynamic> customParameters) {
    _writeLineToFile("------- CUSTOM INFO -------");
    for (final entry in customParameters.entries) {
      _writeLineToFile("${entry.key}: ${entry.value}");
    }
  }

  Future printDeviceInfo() async {
    final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      await deviceInfo.androidInfo.then((androidInfo) {
        _logDeviceParametersFormatted(_loadAndroidParameters(androidInfo));
      });
    }
  }

  Future printApplicationInfo() async {
    final Map<String, dynamic> _applicationParameters = {};
    _applicationParameters["environment"] =
        describeEnum(ApplicationProfileManager.getApplicationProfile());

    ///There is no package info web implementation
    if (!ApplicationProfileManager.isWeb()) {
      await PackageInfo.fromPlatform().then((packageInfo) {
        _applicationParameters["version"] = packageInfo.version;
        _applicationParameters["appName"] = packageInfo.appName;
        _applicationParameters["buildNumber"] = packageInfo.buildNumber;
        _applicationParameters["packageName"] = packageInfo.packageName;
      });
    }

    _logApplicationParametersFormatted(_applicationParameters);
  }

  Map<String, dynamic> _loadAndroidParameters(
      AndroidDeviceInfo androidDeviceInfo) {
    final Map<String, dynamic> deviceParameters = {};
    deviceParameters["id"] = androidDeviceInfo.id;
    deviceParameters["board"] = androidDeviceInfo.board;
    deviceParameters["bootloader"] = androidDeviceInfo.bootloader;
    deviceParameters["brand"] = androidDeviceInfo.brand;
    deviceParameters["device"] = androidDeviceInfo.device;
    deviceParameters["display"] = androidDeviceInfo.display;
    deviceParameters["fingerprint"] = androidDeviceInfo.fingerprint;
    deviceParameters["hardware"] = androidDeviceInfo.hardware;
    deviceParameters["host"] = androidDeviceInfo.host;
    deviceParameters["isPhysicalDevice"] = androidDeviceInfo.isPhysicalDevice;
    deviceParameters["manufacturer"] = androidDeviceInfo.manufacturer;
    deviceParameters["model"] = androidDeviceInfo.model;
    deviceParameters["product"] = androidDeviceInfo.product;
    deviceParameters["tags"] = androidDeviceInfo.tags;
    deviceParameters["type"] = androidDeviceInfo.type;
    deviceParameters["versionBaseOs"] = androidDeviceInfo.version.baseOS;
    deviceParameters["versionCodename"] = androidDeviceInfo.version.codename;
    deviceParameters["versionIncremental"] =
        androidDeviceInfo.version.incremental;
    deviceParameters["versionPreviewSdk"] =
        androidDeviceInfo.version.previewSdkInt;
    deviceParameters["versionRelease"] = androidDeviceInfo.version.release;
    deviceParameters["versionSdk"] = androidDeviceInfo.version.sdkInt;
    deviceParameters["versionSecurityPatch"] =
        androidDeviceInfo.version.securityPatch;
    return deviceParameters;
  }

  void _printLog(String log) {
    if (printLogs) {
      _logger.info(log);
    }
  }

  @override
  List<PlatformType> getSupportedPlatforms() =>
      [PlatformType.android, PlatformType.iOS];

  Future<void> destroy() async {
    await _closeFile();
  }

  Future<void> init() async {
    if (_sink != null) {
      return;
    }

    _fileValidationResult = await _checkFile();
    _openFile();
  }
}
