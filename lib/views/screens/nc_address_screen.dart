import 'package:flutter/material.dart';
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
          if (!_formKey.currentState.validate()) {
            return;
          }
          _formKey.currentState.save();
        },
        onCancel: () => Navigator.popUntil(
          context,
          ModalRoute.withName(YagaHomeScreen.route),
        ),
        labelSelect: "Continue",
        iconSelect: Icons.chevron_right,
      ),
    );
  }

  void _onSave(Uri uri) {
    Navigator.pushNamed(
      context,
      NextCloudLoginScreen.route,
      arguments: uri,
    );
  }
}
