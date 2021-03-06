import 'package:flutter/material.dart';
import 'package:flux_mobile/influxDB.dart';

class VariablesDialog extends StatelessWidget {
  final Function onOK;
  final InfluxDBVariablesList variables;
  final List<String> referencedVariables;

  const VariablesDialog({Key key, this.onOK, @required this.variables, this.referencedVariables})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      children: [
        Container(
          height: 300.0,
          width: 200.0,
          child: InfluxDBVariablesForm(
            variables: variables,
            referencedVariables: referencedVariables,
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: RaisedButton(
                onPressed: (() {
                  Navigator.pop(context);
                  onOK();
                }),
                child: Text("Ok"),
              ),
            ),
          ],
        )
      ],
      title: Text("Variables"),
    );
  }
}