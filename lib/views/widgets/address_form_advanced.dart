import 'package:flutter/material.dart';
import 'package:string_validator/string_validator.dart';

class AddressFormAdvanced extends StatelessWidget {
  final GlobalKey<FormState> _formKey;
  final Function(Uri) _onSave;

  AddressFormAdvanced(this._formKey, this._onSave);

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: TextFormField(
        decoration: InputDecoration(
            labelText: "Fully qualified Nextcloud Server address...",
            icon: Icon(Icons.cloud_queue),
            helperStyle: TextStyle(color: Colors.orange),
            helperText: "Validation is disabled."),
        onSaved: (value) => _onSave(Uri.parse(rtrim(value, "/"))),
        initialValue: "https://",
      ),
    );
  }
}
