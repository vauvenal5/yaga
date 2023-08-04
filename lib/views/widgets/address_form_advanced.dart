import 'package:flutter/material.dart';
import 'package:validators/sanitizers.dart';

class AddressFormAdvanced extends StatelessWidget {
  final GlobalKey<FormState> _formKey;
  final Function(Uri) _onSave;

  const AddressFormAdvanced(this._formKey, this._onSave);

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: TextFormField(
        decoration: const InputDecoration(
            labelText: "Fully qualified Nextcloud Server address...",
            icon: Icon(Icons.cloud_queue),
            helperStyle: TextStyle(color: Colors.orange),
            helperText: "Validation is disabled."),
        onSaved: (value) => _onSave(
          Uri.parse(rtrim(value?.trim()??'', "/")),
        ),
        initialValue: "https://",
      ),
    );
  }
}
