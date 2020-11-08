import 'package:flutter/material.dart';

class YagaRouteInformationParser extends RouteInformationParser<Uri> {
  @override
  Future<Uri> parseRouteInformation(RouteInformation routeInformation) async {
    return Uri.parse(routeInformation.location);
  }
}
