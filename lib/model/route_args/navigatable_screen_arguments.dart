import 'package:flutter/material.dart';

abstract class NavigatableScreenArguments {
  final Uri uri;

  NavigatableScreenArguments({@required this.uri});
}