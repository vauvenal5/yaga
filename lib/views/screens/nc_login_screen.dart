import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:yaga/managers/nextcloud_manager.dart';
import 'package:yaga/model/nc_login_data.dart';
import 'package:yaga/utils/service_locator.dart';
import 'package:yaga/views/screens/yaga_home_screen.dart';

class NextCloudLoginScreen extends StatelessWidget {
  static const String route = "/nc/login";
  final Uri _url;

  NextCloudLoginScreen(this._url) {
    WebView.platform = SurfaceAndroidWebView();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("Sign in..."),
        ),
        body: WebView(
          key: UniqueKey(),
          initialUrl: this._url.toString(),
          userAgent: "Nextcloud Yaga",
          javascriptMode: JavascriptMode.unrestricted,
          onWebViewCreated: (WebViewController webViewController) {
            webViewController.loadUrl(
                this._url.toString() + "/index.php/login/flow",
                headers: <String, String>{"OCS-APIREQUEST": "true"});
          },
          navigationDelegate: (NavigationRequest request) {
            if (request.url.startsWith("nc")) {
              //string of type: nc://login/server:<server>&user:<loginname>&password:<password>
              Map<String, String> ncParas = request.url
                  .split("nc://login/")[1]
                  .split("&")
                  .map((e) => e.split(":"))
                  .map((e) => <String, String>{e.removeAt(0): e.join(":")})
                  .reduce((value, element) {
                value.addAll(element);
                return value;
              });

              getIt.get<NextCloudManager>().loginCommand(NextCloudLoginData(
                  Uri.parse(ncParas[NextCloudLoginDataKeys.server]),
                  ncParas[NextCloudLoginDataKeys.user],
                  ncParas[NextCloudLoginDataKeys.password]));

              Navigator.popUntil(
                  context, ModalRoute.withName(YagaHomeScreen.route));
              return NavigationDecision.prevent;
            }

            return NavigationDecision.navigate;
          },
        ));
  }
}
