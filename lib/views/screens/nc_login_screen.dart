import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:yaga/managers/nextcloud_manager.dart';
import 'package:yaga/model/nc_login_data.dart';
import 'package:yaga/utils/nextcloud_client_factory.dart';
import 'package:yaga/utils/service_locator.dart';
import 'package:yaga/views/screens/yaga_home_screen.dart';

class NextCloudLoginScreen extends StatelessWidget {
  static const String route = "/nc/login";
  final Uri _url;

  const NextCloudLoginScreen(this._url);

  @override
  Widget build(BuildContext context) {
    final WebViewController controller = WebViewController()
      ..setUserAgent(getIt.get<NextCloudClientFactory>().userAgent)
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (NavigationRequest request) async {
            if (request.url.startsWith("nc")) {
              //string of type: nc://login/server:<server>&user:<loginname>&password:<password>
              final Map<String, String> ncParas = request.url
                  .split("nc://login/")[1]
                  .split("&")
                  .map((e) => e.split(":"))
                  .map((e) => <String, String>{e.removeAt(0): e.join(":")})
                  .reduce((value, element) {
                value.addAll(element);
                return value;
              });

              getIt.get<NextCloudManager>().loginCommand(NextCloudLoginData(
                    Uri.parse(ncParas[NextCloudLoginDataKeys.server]!),
                    Uri.decodeComponent(ncParas[NextCloudLoginDataKeys.user]!),
                    ncParas[NextCloudLoginDataKeys.password]!,
                  ));

              Navigator.popUntil(
                  context, ModalRoute.withName(YagaHomeScreen.route));
              return NavigationDecision.prevent;
            }

            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(
        Uri.parse("$_url/index.php/login/flow"),
        headers: <String, String>{"OCS-APIREQUEST": "true"},
      );

    return Scaffold(
      appBar: AppBar(
        title: const Text("Sign in..."),
      ),
      body: WebViewWidget(
        controller: controller,
      ),
    );
  }
}
