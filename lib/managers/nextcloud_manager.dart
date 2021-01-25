import 'dart:async';
import 'dart:io';

import 'package:rx_command/rx_command.dart';
import 'package:yaga/model/nc_login_data.dart';
import 'package:rxdart/rxdart.dart';
import 'package:yaga/services/isolateable/local_file_service.dart';
import 'package:yaga/services/isolateable/nextcloud_service.dart';
import 'package:yaga/services/isolateable/system_location_service.dart';
import 'package:yaga/services/secure_storage_service.dart';
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

  NextCloudManager(
    this._nextCloudService,
    this._secureStorageService,
    this._localFileService,
    this._systemLocationService,
  ) {
    this.loginCommand = RxCommand.createFromStream(
        (param) => this._createLoginDataPersisStream(param));
    this.loginCommand.listen((value) => this._internalLoginCommand(value));

    this._internalLoginCommand = RxCommand.createSync((param) => param);
    this._internalLoginCommand.listen((event) async {
      final origin = await _nextCloudService.login(event);

      if (event.id == "" || event.displayName == "") {
        await _secureStorageService.savePreference(
            NextCloudLoginDataKeys.id, origin.username);
        await _secureStorageService.savePreference(
            NextCloudLoginDataKeys.displayName, origin.displayName);
      }

      updateLoginStateCommand(event);
      updateAvatarCommand();
    });

    this.updateLoginStateCommand = RxCommand.createSync(
      (param) => param,
      initialLastResult: NextCloudLoginData.empty(),
    );

    this.logoutCommand = RxCommand.createFromStream(
      (_) => this._createLoginDataPersisStream(NextCloudLoginData.empty()),
    );
    this
        .logoutCommand
        .doOnData((event) => _nextCloudService.logout())
        .listen((value) {
      this.updateLoginStateCommand(value);
      this.updateAvatarCommand();
    });

    this.updateAvatarCommand = RxCommand.createAsync(
        (_) => _handleAvatarUpdate(),
        initialLastResult: _avatarFile);
  }

  Future<File> _handleAvatarUpdate() async {
    File avatar = _avatarFile;
    if (this._nextCloudService.isLoggedIn()) {
      return this
          ._nextCloudService
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
              .absoluteUriFromInternal(_systemLocationService.tmpAppDirUri)
              .path,
          "${_nextCloudService.origin?.userDomain}.avatar",
        ),
      );

  Future<NextCloudManager> init() async {
    String server = await _secureStorageService
        .loadPreference(NextCloudLoginDataKeys.server);
    String user =
        await _secureStorageService.loadPreference(NextCloudLoginDataKeys.user);
    String password = await _secureStorageService
        .loadPreference(NextCloudLoginDataKeys.password);
    String userId =
        await _secureStorageService.loadPreference(NextCloudLoginDataKeys.id);
    String displayName = await _secureStorageService
        .loadPreference(NextCloudLoginDataKeys.displayName);

    if (server != "" && user != "" && password != "") {
      Completer<NextCloudManager> login = Completer();
      this
          .updateLoginStateCommand
          .where((event) => !login.isCompleted)
          .listen((value) => login.complete(this));
      this._internalLoginCommand(NextCloudLoginData(
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
