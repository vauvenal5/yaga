import 'package:flutter/material.dart';
import 'package:yaga/views/screens/nc_login_screen.dart';
import 'package:yaga/views/screens/yaga_home_screen.dart';
import 'package:string_validator/string_validator.dart';

class NextCloudAddressScreen extends StatefulWidget {
  static const route = "/nc/address";

  NextCloudAddressScreen({Key key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _NextCloudAddressScreenState();
}

class _NextCloudAddressScreenState extends State<NextCloudAddressScreen> {
  final _formKey = GlobalKey<FormState>();

  String _addHttps(String value) {
    if (value.startsWith("https://")) {
      return value;
    }

    return "https://" + value;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("Server Address"),
        ),
        body: Center(
            child: Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: TextFormField(
                    decoration: InputDecoration(
                        labelText: "Nextcloud Server address https://...",
                        icon: Icon(Icons.cloud_queue)),
                    onSaved: (value) => Navigator.pushNamed(
                        context, NextCloudLoginScreen.route,
                        arguments: Uri.parse('https://${rtrim(value, "/")}')),
                    validator: (value) {
                      if (value.startsWith("https://") ||
                          value.startsWith("http://")) {
                        return "Https will be added automaically.";
                      }
                      return isURL("https://$value")
                          ? null
                          : "Please enter a valid URL.";
                    },
                  ),
                ))),
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
                context, ModalRoute.withName(YagaHomeScreen.route));
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
}
