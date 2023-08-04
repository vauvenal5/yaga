import 'dart:io';

import 'package:flutter/material.dart';
import 'package:rx_command/rx_command.dart';

class AvatarWidget extends StatelessWidget {
  final File? _avatar;
  final RxCommand<void, File>? _command;
  final IconData? _iconData;
  final double _radius;
  final bool border;

  const AvatarWidget(this._avatar, {double radius = 14, this.border = true})
      : _command = null,
        _iconData = null,
        _radius = radius;
  const AvatarWidget.command(this._command,
      {double radius = 14, this.border = true})
      : _avatar = null,
        _iconData = null,
        _radius = radius;
  const AvatarWidget.icon(this._iconData,
      {double radius = 14, this.border = true})
      : _avatar = null,
        _command = null,
        _radius = radius;
  const AvatarWidget.phone({double radius = 14, this.border = true})
      : _avatar = null,
        _iconData = Icons.phone_android,
        _command = null,
        _radius = radius;
  const AvatarWidget.sd({double radius = 14, this.border = true})
      : _avatar = null,
        _iconData = Icons.sd_card_outlined,
        _command = null,
        _radius = radius;

  Widget _buildAvatar(BuildContext context, File? data) {
    if (border) {
      return CircleAvatar(
        radius: _radius + 1,
        backgroundColor: Theme.of(context).primaryColor,
        child: _getInnerAvatar(context, data),
      );
    }

    return _getInnerAvatar(context, data);
  }

  Widget _getInnerAvatar(BuildContext context, File? data) {
    if (data != null && data.existsSync()) {
      return CircleAvatar(
        radius: _radius,
        backgroundImage: FileImage(data),
      );
    }

    if (_iconData != null) {
      return _getIconAvatar(context, _iconData!);
    }

    return _getIconAvatar(context, Icons.cloud);
  }

  Widget _getIconAvatar(BuildContext context, IconData iconData) {
    return CircleAvatar(
      radius: _radius,
      backgroundColor: Theme.of(context).primaryIconTheme.color,
      child: Icon(
        iconData,
        size: _radius + 10,
        color: Colors.black,
      ),
    );
  }

  Widget _buildAvatarFromStream(BuildContext context) {
    return StreamBuilder<File>(
      stream: _command,
      initialData: _command!.lastResult,
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
