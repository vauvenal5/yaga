import 'package:flutter/material.dart';
import 'package:validators/sanitizers.dart';
import 'package:validators/validators.dart';

class AddressFormSimple extends StatelessWidget {
  final GlobalKey<FormState> _formKey;
  final Function(Uri) _onSave;

  AddressFormSimple(this._formKey, this._onSave);

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: TextFormField(
        decoration: InputDecoration(
            labelText: "Nextcloud Server address https://...",
            icon: Icon(Icons.cloud_queue)),
        onSaved: (value) => _onSave(
          Uri.parse('https://${rtrim(value.trim(), "/")}'),
        ),
        validator: (value) {
          value = value.trim();
          if (value.startsWith("https://") || value.startsWith("http://")) {
            return "Https will be added automaically.";
          }
          return isURL("https://$value") ? null : "Please enter a valid URL.";
        },
      ),
    );
  }
}
