import 'package:flutter/material.dart';
import 'package:flux_mobile/influxDB.dart';
import 'package:jigowatt/queryList.dart';
import 'package:rapido/rapido.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
      ),
      home: MyHomePage(title: 'Jigowatt'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  InfluxDBAPI api;
  String activeAccountName;
  InfluxDBVariablesList variables;

  AccountReadyState _accountReadyState = AccountReadyState.None;

  DocumentList influxdbInstances = DocumentList(
    "account",
    labels: {
      "active": "active?",
      "Friendly Name": "name",
      "Org Id": "org",
      "URL": "url",
      "Token": "token secret"
    },
    persistenceProvider: SecretsPercistence(),
  );

  DocumentList influxDBQueries = DocumentList(
    "query",
    labels: {
      "Friendly Name": "name",
      "Flux": "queryString",
      "Display Type": "type",
    },
  );

  _initAccount() {
    Document activeDoc;
    influxdbInstances.forEach((Document doc) {
      if (doc["active?"]) {
        activeDoc = doc;
        return;
      }
    });
    if (activeDoc == null && influxdbInstances.length > 0) {
      influxdbInstances[0]["active"] = true;
      activeDoc = influxdbInstances[0];
    }
    if (activeDoc != null) {
      onActiveAccountChanged(activeDoc);
    }
  }

  void onActiveAccountChanged(Document activeDoc) {
    api = InfluxDBAPI(
      influxDBUrl: activeDoc["url"],
      org: activeDoc["org"],
      token: activeDoc["token secret"],
    );
    activeAccountName = activeDoc["name"];
    if (this.mounted)
      setState(() {
        _accountReadyState = AccountReadyState.InProgress;
      });
    api.variables().then((InfluxDBVariablesList vars) {
      variables = vars;
      if (this.mounted)
        setState(() {
          _accountReadyState = AccountReadyState.Ready;
        });
    });
  }

  @override
  void initState() {
    if (influxdbInstances.documentsLoaded) {
      _initAccount();
    } else {
      influxdbInstances.onLoadComplete = (DocumentList list) {
        _initAccount();
        if (this.mounted) {
          setState(() {});
        }
      };
    }
    influxDBQueries.onLoadComplete = (DocumentList list) {
      if (this.mounted) {
        setState(() {});
      }
    };

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Container(
        width: MediaQuery.of(context).size.width * 0.85,
        child: Scaffold(
          body: ListView(
            children: [
              Container(
                color: Theme.of(context).secondaryHeaderColor,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text("Jigowatt"),
                ),
              ),
              Divider(),
              ListTile(
                title: Text("Queries"),
                leading: Icon(Icons.query_builder),
              ),
              Divider(),
              ListTile(title: Text("DASHBOARDS")),
              Divider(),
            ],
          ),
        ),
      ),
      appBar: AppBar(
        title: Text("Jigowatt"),
        actions: [
          IconButton(
              icon: Icon(Icons.account_circle_rounded),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (BuildContext context) {
                    return DocumentListScaffold(
                      influxdbInstances,
                      customItemBuilder:
                          (int index, Document doc, BuildContext context) {
                        return ListTile(
                          title: Text(doc["name"]),
                          trailing: DocumentActionsButton(influxdbInstances,
                              index: index),
                          leading: Switch(
                            value: doc["active?"],
                            onChanged: (bool value) {
                              if (doc["active?"] && value) return;
                              if (value) {
                                influxdbInstances.forEach((Document d) {
                                  d["active?"] = false;
                                });
                                doc["active?"] = true;
                                onActiveAccountChanged(doc);
                                if (this.mounted) {
                                  setState(() {});
                                }
                              }
                            },
                          ),
                        );
                      },
                      emptyListWidget: Center(
                        child: Text("Use + to start adding accounts"),
                      ),
                    );
                  }),
                );
                _initAccount();
                setState(() {});
              })
        ],
      ),
      body: mainBody(),
    );
  }

  Widget mainBody() {
    if (influxdbInstances.documentsLoaded && influxdbInstances.length == 0) {
      return Center(
        child: Text("Use the account button to create an account"),
      );
    }
    if (_accountReadyState == AccountReadyState.InProgress) {
      return Center(
        child: CircularProgressIndicator(),
      );
    }
    if (_accountReadyState == AccountReadyState.Ready) {
      return QueryListScaffold(
        activeAccountName: activeAccountName,
        api: api,
        influxDBQueries: influxDBQueries,
        variables: variables,
      );
    }
    return Container();
  }
}

enum AccountReadyState { None, InProgress, Ready }
