import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:rx_command/rx_command.dart';

class AvatarWidget extends StatelessWidget {
  final Uint8List _avatarBytes;
  final RxCommand<String, Uint8List> _command;
  final double _radius;

  AvatarWidget(this._avatarBytes, {double radius = 20}) : this._command = null, this._radius = radius;
  AvatarWidget.command(this._command, {double radius = 20}) : _avatarBytes = null, this._radius = radius;

  Widget _buildAvatar(BuildContext context, Uint8List data) {
    if(data == null) {
      return CircleAvatar(
        radius: this._radius,
        backgroundColor: Theme.of(context).accentColor,
        child: Text("N/A"),
      );
    }
    return CircleAvatar(
      radius: this._radius,
      backgroundImage: MemoryImage(data),
    );
  }

  Widget _buildAvatarFromStream(BuildContext context) {
    return StreamBuilder<Uint8List>(
      stream: _command,
      initialData: _command.lastResult,
      builder: (context, snapshot) => _buildAvatar(context, snapshot.data),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _command==null?_buildAvatar(context, _avatarBytes):_buildAvatarFromStream(context);
  }
}