import 'dart:async';
import 'dart:io';

import 'package:rx_command/rx_command.dart';
import 'package:yaga/model/nc_login_data.dart';
import 'package:rxdart/rxdart.dart';
import 'package:yaga/services/isolateable/local_file_service.dart';
import 'package:yaga/services/isolateable/nextcloud_service.dart';
import 'package:yaga/services/isolateable/system_location_service.dart';
import 'package:yaga/services/secure_storage_service.dart';
import 'package:yaga/utils/self_signed_cert_handler.dart';
import 'package:yaga/utils/uri_utils.dart';

class NextCloudManager {
  RxCommand<NextCloudLoginData, NextCloudLoginData> loginCommand;
  RxCommand<NextCloudLoginData, NextCloudLoginData> _internalLoginCommand;
  //todo: this command has a bad naming since it only gets triggered on login not logout
  RxCommand<NextCloudLoginData, NextCloudLoginData> updateLoginStateCommand;
  RxCommand<void, NextCloudLoginData> logoutCommand;

  RxCommand<void, File> updateAvatarCommand;

  final SecureStorageService _secureStorageService;
  final NextCloudService _nextCloudService;
  final LocalFileService _localFileService;
  final SystemLocationService _systemLocationService;
  final SelfSignedCertHandler _selfSignedCertHandler;

  NextCloudManager(
    this._nextCloudService,
    this._secureStorageService,
    this._localFileService,
    this._systemLocationService,
    this._selfSignedCertHandler,
  ) {
    loginCommand = RxCommand.createFromStream(
        (param) => _createLoginDataPersisStream(param));
    loginCommand.listen((value) => _internalLoginCommand(value));

    _internalLoginCommand = RxCommand.createSync((param) => param);
    _internalLoginCommand.listen((event) async {
      final origin = await _nextCloudService.login(event);

      if (event.id == "" || event.displayName == "") {
        await _selfSignedCertHandler.persistCert();
        await _secureStorageService.savePreference(
            NextCloudLoginDataKeys.id, origin.username);
        await _secureStorageService.savePreference(
            NextCloudLoginDataKeys.displayName, origin.displayName);
      }

      updateLoginStateCommand(event);
      updateAvatarCommand();
    });

    updateLoginStateCommand = RxCommand.createSync(
      (param) => param,
      initialLastResult: NextCloudLoginData.empty(),
    );

    logoutCommand = RxCommand.createFromStream(
      (_) => _createLoginDataPersisStream(NextCloudLoginData.empty()),
    );
    logoutCommand
        .doOnData((event) => _nextCloudService.logout())
        .listen((value) {
      _selfSignedCertHandler.revokeCert();
      updateLoginStateCommand(value);
      updateAvatarCommand();
    });

    updateAvatarCommand = RxCommand.createAsync(
        (_) => _handleAvatarUpdate(),
        initialLastResult: _avatarFile);
  }

  Future<File> _handleAvatarUpdate() async {
    final File avatar = _avatarFile;
    if (_nextCloudService.isLoggedIn()) {
      return _nextCloudService
          .getAvatar()
          .then(
            (value) => _localFileService.createFile(
              file: avatar,
              bytes: value,
            ),
          )
          .catchError((_) => avatar);
    }
    _localFileService.deleteFile(avatar);
    return avatar;
  }

  File get _avatarFile => File(
        UriUtils.chainPathSegments(
          _systemLocationService
              .absoluteUriFromInternal(_systemLocationService.internalCache.uri)
              .path,
          "${_nextCloudService.origin?.userDomain}.avatar",
        ),
      );

  Future<NextCloudManager> init() async {
    final String server = await _secureStorageService
        .loadPreference(NextCloudLoginDataKeys.server);
    final String user =
        await _secureStorageService.loadPreference(NextCloudLoginDataKeys.user);
    final String password = await _secureStorageService
        .loadPreference(NextCloudLoginDataKeys.password);
    final String userId =
        await _secureStorageService.loadPreference(NextCloudLoginDataKeys.id);
    final String displayName = await _secureStorageService
        .loadPreference(NextCloudLoginDataKeys.displayName);

    if (server != "" && user != "" && password != "") {
      final Completer<NextCloudManager> login = Completer();
      updateLoginStateCommand
          .where((event) => !login.isCompleted)
          .listen((value) => login.complete(this));
      _internalLoginCommand(NextCloudLoginData(
        Uri.parse(server),
        user,
        password,
        id: userId,
        displayName: displayName,
      ));
      return login.future;
    }

    return this;
  }

  Stream<NextCloudLoginData> _createLoginDataPersisStream(
      NextCloudLoginData data) {
    return ForkJoinStream.list([
      _secureStorageService
          .savePreference(NextCloudLoginDataKeys.server, data.server.toString())
          .asStream(),
      _secureStorageService
          .savePreference(NextCloudLoginDataKeys.user, data.user)
          .asStream(),
      _secureStorageService
          .savePreference(NextCloudLoginDataKeys.password, data.password)
          .asStream(),
      _secureStorageService
          .savePreference(NextCloudLoginDataKeys.id, data.id)
          .asStream(),
      _secureStorageService
          .savePreference(NextCloudLoginDataKeys.displayName, data.displayName)
          .asStream(),
    ]).map((_) => data);
  }
}
