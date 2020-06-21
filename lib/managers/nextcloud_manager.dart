import 'dart:typed_data';

import 'package:rx_command/rx_command.dart';
import 'package:yaga/model/nc_login_data.dart';
import 'package:rxdart/rxdart.dart';
import 'package:yaga/services/nextcloud_service.dart';
import 'package:yaga/services/secure_storage_service.dart';

class NextCloudManager {
  RxCommand<NextCloudLoginData, NextCloudLoginData> loginCommand;
  RxCommand<NextCloudLoginData, NextCloudLoginData> _internalLoginCommand;
  RxCommand<void, NextCloudLoginData> loadLoginDataCommand;
  RxCommand<NextCloudLoginData, NextCloudLoginData> updateLoginStateCommand;
  RxCommand<void, NextCloudLoginData> logoutCommand;

  RxCommand<String, Uint8List> updateAvatarCommand;

  SecureStorageService _secureStorageService;
  NextCloudService _nextCloudService;

  NextCloudManager(this._nextCloudService, this._secureStorageService) {
    this.loginCommand = RxCommand.createFromStream((param) => this._createLoginDataPersisStream(param));
    this.loginCommand.listen((value) => this._internalLoginCommand(value));

    this._internalLoginCommand = RxCommand.createSync((param) => param);
    this._internalLoginCommand
      .doOnData((event) => _nextCloudService.login(event.server, event.user, event.password))
      .listen((event) {
        updateLoginStateCommand(event);
        updateAvatarCommand(event.user);
      });

    this.updateLoginStateCommand = RxCommand.createSync((param) => param, initialLastResult: NextCloudLoginData(null, "", ""));

    this.loadLoginDataCommand = RxCommand.createFromStream((_) => ForkJoinStream.list([
        _secureStorageService.loadPreference(NextCloudLoginDataKeys.server).asStream(),
        _secureStorageService.loadPreference(NextCloudLoginDataKeys.user).asStream(),
        _secureStorageService.loadPreference(NextCloudLoginDataKeys.password).asStream(),
      ])
      .where((event) => event[0] != "")
      .where((event) => event[1] != "")
      .where((event) => event[2] != "")
      .map((event) => NextCloudLoginData(Uri.parse(event[0]), event[1], event[2]))
    );
    this.loadLoginDataCommand.listen((event) => _internalLoginCommand(event));

    this.logoutCommand = RxCommand.createFromStream((_) => this._createLoginDataPersisStream(NextCloudLoginData(null,"","")));
    this.logoutCommand.doOnData((event) => _nextCloudService.logout())
    .listen((value) => this.updateLoginStateCommand(value));

    this.updateAvatarCommand = RxCommand.createAsync((user) => this._nextCloudService.getAvatar(user), initialLastResult: null);
  }

  Stream<NextCloudLoginData> _createLoginDataPersisStream(NextCloudLoginData data) {
    return ForkJoinStream.list([
      _secureStorageService.savePreference(NextCloudLoginDataKeys.server, data.server.toString()).asStream(),
      _secureStorageService.savePreference(NextCloudLoginDataKeys.user, data.user).asStream(),
      _secureStorageService.savePreference(NextCloudLoginDataKeys.password, data.password).asStream(),
    ])
    .map((_) => data);
  }
}