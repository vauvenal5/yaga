import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:nextcloud/nextcloud.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:yaga/managers/nextcloud_manager.dart';
import 'package:yaga/model/nc_login_data.dart';
import 'package:yaga/utils/logger.dart';
import 'package:yaga/utils/nextcloud_client_factory.dart';
import 'package:yaga/utils/self_signed_cert_handler.dart';
import 'package:yaga/utils/service_locator.dart';
import 'package:yaga/views/screens/nc_login_screen.dart';
import 'package:yaga/views/screens/yaga_home_screen.dart';
import 'package:yaga/views/widgets/action_danger_dialog.dart';
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
  final _logger = YagaLogger.getLogger(_NextCloudAddressScreenState);

  GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool validation = true;
  bool _inBrowser = false;
  bool _disposing = false;

  @override
  void dispose() {
    _logger.fine("Disposing");
    _disposing = true;
    super.dispose();
  }

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
    final client =
        getIt.get<NextCloudClientFactory>().createUnauthenticatedClient(uri);

    // check if we detect a self-signed cert, if yes, enforce browser flow
    if (!this._inBrowser) {
      try {
        await client.user.getUser();
      } on HandshakeException catch (e) {
        this._inBrowser = true;
      } on RequestException catch (e) {
        _logger.info("Proper HTTPS detected.");
      }
    }

    if (this._inBrowser) {
      getIt.get<SelfSignedCertHandler>().badCertificateCallback =
          this._askForCertApprovalBuilder(uri);
      //todo: should we move this into the manager/service?
      //todo: is canLaunch/launch a UI component?

      LoginFlowInit init;
      try {
        init = await client.login.initLoginFlow();
      } catch (e) {
        _logger.severe("Could not init login flow", e);
        getIt.get<SelfSignedCertHandler>().revokeCert();
        getIt.get<SelfSignedCertHandler>().badCertificateCallback = null;
        return;
      }

      if (await canLaunch(init.login)) {
        await launch(init.login);
        LoginFlowResult res;

        while (res == null && !_disposing) {
          try {
            _logger.fine("Requesting");
            res = await client.login.pollLogin(init);
          } on RequestException catch (e) {
            if (e.statusCode != 404) {
              throw e;
            }
          }
        }

        if (_disposing) {
          // revoke tmp granted cert if login is aborted
          getIt.get<SelfSignedCertHandler>().revokeCert();
          return;
        }

        getIt.get<NextCloudManager>().loginCommand(
              NextCloudLoginData(
                Uri.parse(res.server),
                res.loginName,
                res.appPassword,
              ),
            );

        getIt.get<SelfSignedCertHandler>().badCertificateCallback = null;

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

  Future<Function> Function(
    String subject,
    String issuer,
    String fingerprint,
  ) _askForCertApprovalBuilder(Uri uri) {
    return (
      String subject,
      String issuer,
      String fingerprint,
    ) {
      final completer = Completer<Function>();
      showDialog(
        context: context,
        builder: (context) => ActionDangerDialog(
          title: "Untrusted Certificate",
          cancelButton: "Cancel",
          aggressiveAction: "Trust",
          action: (agg) {
            if (agg) {
              completer.complete(() => this._onSave(uri));
            } else {
              completer.complete(null);
            }
          },
          bodyBuilder: (context) => <Widget>[
            Text('Do you trust this certificate?'),
            Text(''),
            Text('Subject: $subject'),
            Text('Issuer: $issuer'),
            Text('Fingerprint: $fingerprint'),
            Text(''),
            Text(
              'Please note that Nextcloud Yaga only performs fingerprint comparison on self-signed certificates!',
            ),
          ],
        ),
      ).whenComplete(
        () => getIt.get<SelfSignedCertHandler>().badCertificateCallback = null,
      );
      return completer.future;
    };
  }
}
