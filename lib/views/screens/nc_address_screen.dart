import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:nextcloud/core.dart';
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

  const NextCloudAddressScreen({Key? key}) : super(key: key);

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
        title: const Text("Server Address"),
        actions: [
          IconButton(
            icon: validation
                ? const Icon(Icons.report)
                : const Icon(Icons.report_off),
            onPressed: () => setState(() {
              validation = !validation;
              _formKey = GlobalKey<FormState>();
            }),
          ),
        ],
      ),
      body: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: validation
              ? AddressFormSimple(_formKey, _onSave)
              : AddressFormAdvanced(_formKey, _onSave),
        ),
      ),
      resizeToAvoidBottomInset: true,
      bottomNavigationBar: SelectCancelBottomNavigation(
        onCommit: () {
          _inBrowser = false;
          _validateAndSaveForm();
        },
        //todo: why does this cause a refetch?!
        onCancel: () => Navigator.popUntil(
          context,
          ModalRoute.withName(YagaHomeScreen.route),
        ),
        labelSelect: "Continue",
        iconSelect: Icons.chevron_right,
        betweenItems: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.open_in_browser),
            label: "Open in browser",
          ),
        ],
        betweenItemsCallbacks: [
          () {
            _inBrowser = true;
            _validateAndSaveForm();
          }
        ],
      ),
    );
  }

  void _validateAndSaveForm() {
    if (!(_formKey.currentState?.validate()??false)) {
      return;
    }
    _formKey.currentState?.save();
  }

  Future<void> _onSave(Uri uri) async {
    final client =
        getIt.get<NextCloudClientFactory>().createUnauthenticatedClient(uri);

    // check if we detect a self-signed cert, if yes, enforce browser flow
    if (!_inBrowser) {
      try {
        await client.httpClient.getUrl(uri);
        _logger.info("Proper HTTPS detected.");
      } on HandshakeException {
        _inBrowser = true;
      }
    }

    if (_inBrowser) {
      getIt.get<SelfSignedCertHandler>().badCertificateCallback =
          _askForCertApprovalBuilder(uri);
      //todo: should we move this into the manager/service?
      //todo: is canLaunch/launch a UI component?

      LoginFlowV2 init;
      try {
        init = await client.core.clientFlowLoginV2.init().then((value) => value.body);
      } catch (e) {
        _logger.severe("Could not init login flow", e);
        getIt.get<SelfSignedCertHandler>().revokeCert();
        getIt.get<SelfSignedCertHandler>().badCertificateCallback = null;
        return;
      }

      try {
        // final res = await client.core.clientFlowLoginV2.poll(token: init.poll.token).then((value) => value.body);
        if(await launchUrl(Uri.parse(init.login), mode: LaunchMode.externalApplication,)) {
          // await launchUrlString(init.login, mode: LaunchMode.externalApplication);
          LoginFlowV2Credentials? res;

          while (res == null) {
            _logger.fine("Requesting");
            try {
              res =
              await client.core.clientFlowLoginV2.poll(token: init.poll.token)
                  .then((value) => value.body);
            } on DynamiteApiException catch (e) {
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
              Uri.parse(res!.server),
              res.loginName,
              res.appPassword,
            ),
          );

          getIt
              .get<SelfSignedCertHandler>()
              .badCertificateCallback = null;

          if (!mounted) return;

          Navigator.popUntil(
            context,
            ModalRoute.withName(YagaHomeScreen.route),
          );
        }
      } on Exception catch (e) {
        //todo: show message to user
        _logger.severe('Could not launch $uri', e);
      }
      return;
    }

    if (!mounted) return;

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
              completer.complete(() => _onSave(uri));
            } else {
              completer.complete(null);
            }
          },
          bodyBuilder: (context) => <Widget>[
            const Text('Do you trust this certificate?'),
            const Text(''),
            Text('Subject: $subject'),
            Text('Issuer: $issuer'),
            Text('Fingerprint: $fingerprint'),
            const Text(''),
            const Text(
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
