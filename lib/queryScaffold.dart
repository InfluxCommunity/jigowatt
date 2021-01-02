import 'package:flutter/material.dart';
import 'package:flux_mobile/influxDB.dart';
import 'package:jigowatt/variablesDialog.dart';
import 'package:rapido/rapido.dart';

class QueryScaffold extends StatefulWidget {
  final Document document;
  final InfluxDBAPI api;
  final String activeAccountName;
  final InfluxDBVariablesList variables;

  QueryScaffold(
      {@required this.document,
      @required this.api,
      this.activeAccountName,
      @required this.variables});
  @override
  _QueryScaffoldState createState() => _QueryScaffoldState();
}

class _QueryScaffoldState extends State<QueryScaffold> {
  TextEditingController _nameController;
  TextEditingController _queryStringController;
  List<InfluxDBTable> _tables;
  String _err = "";
  QueryStatus _queryStatus = QueryStatus.None;

  @override
  void initState() {
    _nameController = TextEditingController(text: widget.document["name"]);
    _queryStringController =
        TextEditingController(text: widget.document["queryString"]);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          actions: [
            IconButton(
              icon: Icon(Icons.settings),
              onPressed: () async {
                await showDialog(
                  context: context,
                  builder: (_) => VariablesDialog(
                    variables: widget.variables,
                    onOK: () {
                      setState(() {});
                    },
                  ),
                  barrierDismissible: false,
                );
              },
            )
          ],
          title: Column(
            children: [
              Text("Query"),
              Text(widget.activeAccountName,
                  style: Theme.of(context).textTheme.subtitle1),
            ],
          )),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          if (this.mounted) {
            setState(() {
              _queryStatus = QueryStatus.InProgress;
            });
          }
          InfluxDBQuery query = InfluxDBQuery(
            api: widget.api,
            queryString: _queryStringController.text,
            variables: widget.variables,
          );
          _tables = null;
          _err = "";
          try {
            _tables = await query.execute();
          } on InfluxDBAPIHTTPError catch (e) {
            _err = e.readableMessage();
          }
          if (this.mounted) {
            setState(() {
              _queryStatus = QueryStatus.Complete;
            });
          }
        },
        child: Icon(Icons.play_arrow),
      ),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              child: TextField(
                onChanged: (String s) {
                  widget.document["name"] = _nameController.text;
                },
                onEditingComplete: () {
                  widget.document["name"] = _nameController.text;
                },
                controller: _nameController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: "Quary Name",
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              child: TextField(
                style: TextStyle(fontSize: 12.0, fontFamily: "monospace"),
                controller: _queryStringController,
                onEditingComplete: () {
                  widget.document["queryString"] = _queryStringController.text;
                },
                onChanged: (String s) {
                  widget.document["queryString"] = _queryStringController.text;
                },
                decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: "Query",
                    labelStyle: Theme.of(context).textTheme.subtitle1),
                maxLines: 8,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              child: DropdownButtonFormField(
                value: widget.document["type"],
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: "Display Style",
                ),
                items: [
                  DropdownMenuItem(
                      child: Text("Line Graph"), value: "Line Graph"),
                  DropdownMenuItem(child: Text("Table"), value: "Table"),
                  DropdownMenuItem(
                      child: Text("Single Stat"), value: "Single Stat")
                ],
                onChanged: (value) {
                  if (this.mounted) {
                    setState(() {
                      widget.document["type"] = value;
                    });
                  }
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: resultsWidget(),
          ),
        ],
      ),
    );
  }

  Widget resultsWidget() {
    if (_queryStatus == QueryStatus.None) {
      return Center(
        child: Text(
            "Type in a query, choose on output type, and click the Run button"),
      );
    }
    if (_queryStatus == QueryStatus.InProgress) {
      return Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_err != "") {
      return Center(
        child: Text(_err),
      );
    }

    switch (widget.document["type"]) {
      case "Line Graph":
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            constraints: BoxConstraints(maxHeight: 350.00),
            child: InfluxDBLineChartWidget(
              tables: _tables,
              yAxis: InfluxDBLineChartAxis(tables: _tables),
              xAxis: InfluxDBLineChartAxis(),
            ),
          ),
        );
      case "Table":
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            constraints: BoxConstraints(maxHeight: 350.00),
            child: InfluxDBTableWidget(
              tables: _tables,
            ),
          ),
        );

      default:
        return Center(
          child: Text("something went wrong"),
        );
    }
  }
}

enum QueryStatus { None, InProgress, Complete }
