import 'package:flutter/material.dart';
import 'package:flux_mobile/influxDB.dart';
import 'package:rapido/rapido.dart';

import 'queryForm.dart';

class QueryListScaffold extends StatefulWidget {
  final DocumentList influxDBQueries;
  final InfluxDBAPI api;
  final String activeAccountName;
  final InfluxDBVariablesList variables;

  const QueryListScaffold(
      {Key key,
      @required this.influxDBQueries,
      @required this.api,
      @required this.activeAccountName,
      @required this.variables})
      : super(key: key);

  _QueryListScaffoldState createState() => _QueryListScaffoldState();
}

class _QueryListScaffoldState extends State<QueryListScaffold> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Queries"),
      ),
      body: QueryListItem(
        influxdbQueries: widget.influxDBQueries,
        api: widget.api,
        activeAccountName: widget.activeAccountName,
        variables: widget.variables,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Document newDoc = Document(
            initialValues: {
              "type": "Line Graph",
              "queryString": "",
              "name": "Untitled Query"
            },
          );
          Navigator.push(
            context,
            MaterialPageRoute(builder: (BuildContext context) {
              widget.influxDBQueries.add(newDoc);

              return QueryForm(
                document: newDoc,
                api: widget.api,
                activeAccountName: widget.activeAccountName,
                variables: widget.variables,
              );
            }),
          );
          setState(() {});
        },
        child: Icon(Icons.add),
      ),
    );
  }
}

class QueryListItem extends StatelessWidget {
  const QueryListItem({
    Key key,
    @required this.influxdbQueries,
    @required InfluxDBAPI api,
    @required this.activeAccountName,
    @required this.variables,
  })  : _api = api,
        super(key: key);

  final DocumentList influxdbQueries;
  final InfluxDBAPI _api;
  final String activeAccountName;
  final InfluxDBVariablesList variables;

  @override
  Widget build(BuildContext context) {
    return DocumentListView(
      influxdbQueries,
      customItemBuilder: (int index, Document doc, BuildContext context) {
        return Dismissible(
          direction: DismissDirection.startToEnd,
          key: ObjectKey(doc.id),
          background: ListTile(
            tileColor: Colors.red,
            leading: Icon(Icons.delete_forever),
          ),
          child: ListTile(
            title: Text(doc["name"]),
            onTap: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (BuildContext context) {
                return QueryForm(
                  document: doc,
                  api: _api,
                  activeAccountName: activeAccountName,
                  variables: variables,
                );
              }));
            },
          ),
          onDismissed: (DismissDirection dirction) {
            influxdbQueries.remove(doc);
          },
        );
      },
    );
  }
}
