import 'package:flutter/material.dart';

mixin class GridDelegate {
  SliverGridDelegate buildImageGridDelegate(BuildContext context) {
    return const SliverGridDelegateWithMaxCrossAxisExtent(
      maxCrossAxisExtent: 175.0,
      crossAxisSpacing: 2,
      mainAxisSpacing: 2,
    );
  }
}