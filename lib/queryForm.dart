import 'package:flutter/material.dart';
import 'package:flux_mobile/influxDB.dart';
import 'package:rapido/rapido.dart';

class QueryForm extends StatefulWidget {
  final Document document;
  final InfluxDBAPI api;
  final String activeAccountName;

  QueryForm(
      {@required this.document, @required this.api, this.activeAccountName});
  @override
  _QueryFormState createState() => _QueryFormState();
}

class _QueryFormState extends State<QueryForm> {
  TextEditingController _nameController;
  TextEditingController _queryStringController;
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
          title: Column(
        children: [
          Text("Query"),
          Text(widget.activeAccountName,
              style: Theme.of(context).textTheme.subtitle1),
        ],
      )),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
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
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              child: TextField(
                onEditingComplete: () {
                  widget.document["queryString"] = _queryStringController.text;
                },
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: "Query",
                ),
                maxLines: 5,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              
              child: DropdownButtonFormField(
                value: widget.document["type"],
                decoration: InputDecoration(border: OutlineInputBorder(), labelText: "Display Style",),
                
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
        ],
      ),
    );
  }
}
