import 'package:flutter/material.dart';
import 'package:nextcloud/nextcloud.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:yaga/managers/nextcloud_manager.dart';
import 'package:yaga/model/nc_login_data.dart';
import 'package:yaga/utils/service_locator.dart';
import 'package:yaga/views/screens/nc_login_screen.dart';
import 'package:yaga/views/screens/yaga_home_screen.dart';
import 'package:yaga/views/widgets/address_form_advanced.dart';
import 'package:yaga/views/widgets/address_form_simple.dart';
import 'package:yaga/views/widgets/select_cancel_bottom_navigation.dart';

class NextCloudAddressScreen extends StatefulWidget {
  static const route = "/nc/address";

  NextCloudAddressScreen({Key key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _NextCloudAddressScreenState();
}

class _NextCloudAddressScreenState extends State<NextCloudAddressScreen> {
  GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool validation = true;
  bool _inBrowser = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Server Address"),
        actions: [
          IconButton(
            icon: validation ? Icon(Icons.report) : Icon(Icons.report_off),
            onPressed: () => setState(() {
              validation = !validation;
              _formKey = GlobalKey<FormState>();
            }),
          ),
        ],
      ),
      body: Center(
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 10),
          child: validation
              ? AddressFormSimple(_formKey, _onSave)
              : AddressFormAdvanced(_formKey, _onSave),
        ),
      ),
      resizeToAvoidBottomInset: true,
      bottomNavigationBar: SelectCancelBottomNavigation(
        onCommit: () {
          _inBrowser = false;
          this._validateAndSaveForm();
        },
        //todo: why does this cause a refetch?!
        onCancel: () => Navigator.popUntil(
          context,
          ModalRoute.withName(YagaHomeScreen.route),
        ),
        labelSelect: "Continue",
        iconSelect: Icons.chevron_right,
        betweenItems: [
          BottomNavigationBarItem(
            icon: Icon(Icons.open_in_browser),
            label: "Open in browser",
          ),
        ],
        betweenItemsCallbacks: [
          () {
            _inBrowser = true;
            this._validateAndSaveForm();
          }
        ],
      ),
    );
  }

  void _validateAndSaveForm() {
    if (!_formKey.currentState.validate()) {
      return;
    }
    _formKey.currentState.save();
  }

  void _onSave(Uri uri) async {
    if (this._inBrowser) {
      //todo: should we move this into the manager/service?
      //todo: is canLaunch/launch a UI component?
      final client = NextCloudClient.withoutLogin(uri);
      LoginFlowInit init = await client.login.initLoginFlow();

      if (await canLaunch(init.login)) {
        await launch(init.login);
        LoginFlowResult res;
        while (res == null) {
          try {
            res = await client.login.pollLogin(init);
          } on RequestException catch (e) {
            if (e.statusCode != 404) {
              throw e;
            }
          }
        }

        getIt.get<NextCloudManager>().loginCommand(
              NextCloudLoginData(
                Uri.parse(res.server),
                res.loginName,
                res.appPassword,
              ),
            );

        Navigator.popUntil(
          context,
          ModalRoute.withName(YagaHomeScreen.route),
        );
      } else {
        throw 'Could not launch $uri';
      }
      return;
    }

    Navigator.pushNamed(
      context,
      NextCloudLoginScreen.route,
      arguments: uri,
    );
  }
}
