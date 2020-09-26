import 'package:flutter/material.dart';
import 'package:yaga/model/preference.dart';
import 'package:yaga/views/widgets/ok_cancel_button_bar.dart';

class ChoiceSelectorScreen extends StatefulWidget {
  static const String route = "/choiceSelectorScreen";

  final ChoicePreference _choicePreference;
  final void Function() _onCancel;
  final void Function(String) _onSelect;

  ChoiceSelectorScreen(this._choicePreference, this._onSelect, this._onCancel);

  @override
  _ChoiceSelectorScreenState createState() => _ChoiceSelectorScreenState();
}

class _ChoiceSelectorScreenState extends State<ChoiceSelectorScreen> {
  String _choice;

  @override
  void initState() {
    super.initState();
    this._choice = widget._choicePreference.value;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(this.widget._choicePreference.title),
      ),
      body: ListView.separated(
        itemBuilder: (context, index) => RadioListTile(
          title: Text(widget._choicePreference.choices[widget._choicePreference.choices.keys.elementAt(index)]),
          value: widget._choicePreference.choices.keys.elementAt(index), 
          groupValue: _choice, 
          onChanged: (String value) => setState(() => _choice = value)
        ), 
        separatorBuilder: (context, index) => const Divider(), 
        itemCount: widget._choicePreference.choices.length
      ),
      bottomNavigationBar: OkCancelButtonBar(
        onCommit: () {
          this.widget._onSelect(_choice);
        }, 
        onCancel: this.widget._onCancel
      ),
    );
  }
}