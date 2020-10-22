import 'package:flutter/material.dart';

class YagaPopupMenuButton<T> extends StatelessWidget {
  final List<PopupMenuEntry<T>> Function(BuildContext context) itemBuilder;
  final void Function(BuildContext context, T result) handler;

  YagaPopupMenuButton(this.itemBuilder, this.handler);

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<T>(
      offset: Offset(0, 10),
      onSelected: (T result) => handler(context, result),
      itemBuilder: itemBuilder,
    );
  }
}
