import 'dart:io';

import 'package:flutter/material.dart';
import 'package:rx_command/rx_command.dart';

class AvatarWidget extends StatelessWidget {
  final File _avatar;
  final RxCommand<void, File> _command;
  final IconData _iconData;
  final double _radius;
  final bool border;

  AvatarWidget(this._avatar, {double radius = 14, this.border = true})
      : this._command = null,
        this._iconData = null,
        this._radius = radius;
  AvatarWidget.command(this._command, {double radius = 14, this.border = true})
      : _avatar = null,
        this._iconData = null,
        this._radius = radius;
  AvatarWidget.icon(this._iconData, {double radius = 14, this.border = true})
      : _avatar = null,
        this._command = null,
        this._radius = radius;
  AvatarWidget.phone({double radius = 14, this.border = true})
      : _avatar = null,
        this._iconData = Icons.phone_android,
        this._command = null,
        this._radius = radius;

  Widget _buildAvatar(BuildContext context, File data) {
    if (border) {
      return CircleAvatar(
        radius: this._radius + 1,
        backgroundColor: Theme.of(context).primaryColor,
        child: _getInnerAvatar(context, data),
      );
    }

    return _getInnerAvatar(context, data);
  }

  Widget _getInnerAvatar(BuildContext context, File data) {
    if (data != null && data.existsSync()) {
      return CircleAvatar(
        radius: this._radius,
        backgroundImage: FileImage(data),
      );
    }

    if (_iconData != null) {
      return _getIconAvatar(context, _iconData);
    }

    return _getIconAvatar(context, Icons.cloud);
  }

  Widget _getIconAvatar(BuildContext context, IconData iconData) {
    return CircleAvatar(
      radius: this._radius,
      backgroundColor: Theme.of(context).primaryIconTheme.color,
      child: Icon(
        iconData,
        size: this._radius + 10,
        color: Colors.black,
      ),
    );
  }

  Widget _buildAvatarFromStream(BuildContext context) {
    return StreamBuilder<File>(
      stream: _command,
      initialData: _command.lastResult,
      builder: (context, snapshot) => _buildAvatar(context, snapshot.data),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _command == null
        ? _buildAvatar(context, _avatar)
        : _buildAvatarFromStream(context);
  }
}
