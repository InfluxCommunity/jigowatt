import 'package:flutter/material.dart';
import 'package:flux_mobile/influxDB.dart';
import 'package:jigowatt/queryForm.dart';
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
  // List of accounts
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

  DocumentList influxdbQueries = DocumentList(
    "query",
    labels: {
      "Friendly Name": "name",
      "Flux": "queryString",
      "Display Type": "type",
    },
  );

  InfluxDBAPI _api;

  String activeAccountName;
  
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
      setActiveAccount(activeDoc);
    }
  }

  void setActiveAccount(Document activeDoc) {
    _api = InfluxDBAPI(
      influxDBUrl: activeDoc["url"],
      org: activeDoc["org"],
      token: activeDoc["token secret"],
    );
    activeAccountName = activeDoc["name"];
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
    influxdbQueries.onLoadComplete = (DocumentList list) {
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
                                setActiveAccount(doc);
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
                setState(() {
                  
                });
              })
        ],
      ),
      body: Scaffold(
        appBar: AppBar(
          title: Text("Queries"),
        ),
        body: QueryListItem(
            influxdbQueries: influxdbQueries,
            api: _api,
            activeAccountName: activeAccountName),
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
                influxdbQueries.add(newDoc);

                return QueryForm(
                  document: newDoc,
                  api: _api,
                  activeAccountName: activeAccountName,
                );
              }),
            );
            setState(() {});
          },
          child: Icon(Icons.add),
        ),
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
  })  : _api = api,
        super(key: key);

  final DocumentList influxdbQueries;
  final InfluxDBAPI _api;
  final String activeAccountName;

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
