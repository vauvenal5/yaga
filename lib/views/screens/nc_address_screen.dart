import 'package:flutter/material.dart';
import 'package:yaga/views/screens/nc_login_screen.dart';
import 'package:yaga/views/screens/yaga_home_screen.dart';
import 'package:yaga/views/widgets/address_form_advanced.dart';
import 'package:yaga/views/widgets/address_form_simple.dart';

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
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: 1,
          onTap: (index) {
            if (index == 1) {
              if (!_formKey.currentState.validate()) {
                return;
              }
              _formKey.currentState.save();
              return;
            }

            Navigator.popUntil(
              context,
              ModalRoute.withName(YagaHomeScreen.route),
            );
          },
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.close),
              title: Text('Cancel'),
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.chevron_right),
              title: Text('Continue'),
            ),
          ],
        ));
  }

  String _addHttps(String value) {
    if (value.startsWith("https://")) {
      return value;
    }

    return "https://" + value;
  }

  void _onSave(Uri uri) {
    Navigator.pushNamed(
      context,
      NextCloudLoginScreen.route,
      arguments: uri,
    );
  }
}
