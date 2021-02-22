import 'package:flutter/material.dart';
import 'package:flux_mobile/influxDB.dart';
import 'package:rapido/rapido.dart';

import 'queryScaffold.dart';

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
      body: QueryListView(
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

              return QueryScaffold(
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

class QueryListView extends StatelessWidget {
  const QueryListView({
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
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage("assets/logo.png"),
          colorFilter: ColorFilter.mode(
              Colors.white.withOpacity(0.3), BlendMode.dstATop),
        ),
      ),
      customItemBuilder: (int index, Document doc, BuildContext context) {
        return Dismissible(
          direction: DismissDirection.startToEnd,
          key: ObjectKey(doc.id),
          background: ListTile(
            tileColor: Colors.red,
            leading: Icon(Icons.delete_forever),
          ),
          child: ListTile(
            leading: VizTypeWidget(type: doc["type"]),
            title: Text(doc["name"]),
            subtitle: Text(doc["queryString"].split("\n")[0] + " ..."),
            onTap: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (BuildContext context) {
                return QueryScaffold(
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

class VizTypeWidget extends StatelessWidget {
  final String type;

  const VizTypeWidget({Key key, @required this.type}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    switch (type) {
      case "Line Graph":
        return Icon(Icons.stacked_line_chart);
      case "Table":
        return Icon(Icons.table_chart);
      case "Single Stat":
        return Icon(Icons.exposure_plus_1);
      default:
        return Icon(Icons.dashboard);
    }
  }
}
