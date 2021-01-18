import 'package:flutter/material.dart';
import 'package:flux_mobile/influxDB.dart';
import 'package:jigowatt/accountListScaffold.dart';
import 'package:jigowatt/accountScaffold.dart';
import 'package:jigowatt/dashboardScaffold.dart';
import 'package:jigowatt/queryListScaffold.dart';
import 'package:jigowatt/taskListScaffold.dart';
import 'package:rapido/rapido.dart';

import 'bucketsListScaffold.dart';
import 'drawer.dart';
import 'notificationScaffold.dart';

import 'package:permission_handler/permission_handler.dart';

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
        // primarySwatch: Colors.deepPurple,
        primaryColor: Color.fromRGBO(34, 173, 246, 1.0),
        accentColor: Color.fromRGBO(147, 158, 255, 1.0),
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
  DocumentList accountDocs = DocumentList(
    "account",
    labels: {
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
    persistenceProvider: SecretsPercistence(),
  );

  _initAccount() {
    Document activeDoc;
    accountDocs.forEach((Document doc) {
      // ensure there is only one active document
      if (doc["active?"]) {
        if (activeDoc == null) {
          activeDoc = doc;
        } else {
          doc["active?"] = false;
        }
      }
    });

    // ensure there is at least one active document
    if (activeDoc == null && accountDocs.length > 0) {
      accountDocs[0]["active"] = true;
      activeDoc = accountDocs[0];
    }
    if (activeDoc != null) {
      onActiveAccountChanged(activeDoc);
    }
  }

  void onActiveAccountChanged(Document activeDoc) async {
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

    try {
      List<dynamic> futures = await Future.wait<dynamic>([
        api.variables(),
      ]);

      variables = futures[0];

      _mainViewScaffold = QueryListScaffold(
        activeAccountName: activeAccountName,
        api: api,
        influxDBQueries: influxDBQueries,
        variables: variables,
      );
    } catch (e) {
      _mainViewScaffold = Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Center(
                  child: Text(
                    "Unable to load account \"${activeDoc["name"]}\" due to the following error:",
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Center(
                  child: Text(e.toString()),
                ),
              )
            ],
          ),
        ),
      );
    }
    _accountReadyState = AccountReadyState.Ready;
    setState(() {});
  }

  @override
  void initState() {
    _checkPermissions();
    if (accountDocs.documentsLoaded) {
      _initAccount();
    } else {
      accountDocs.onLoadComplete = (DocumentList list) {
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

  _checkPermissions() async {
    PermissionStatus status = await Permission.storage.status;
    if (status.isUndetermined) {
      await Permission.storage.request();
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: JigoWattDrawer(
        activeAccountName: activeAccountName,
        notificationSelected: (InfluxDBNotificationRule notificationRule) {
          setState(() {
            _mainViewScaffold = NotificationScaffold(
              key: ObjectKey(notificationRule.id),
              notificationRule: notificationRule,
              activeAccountName: activeAccountName,
              api: api,
            );
          });
          Navigator.pop(context);
        },
        dashboardSelected: (InfluxDBDashboard dashboard) {
          setState(() {
            _mainViewScaffold = DashboardScaffold(
              key: ObjectKey(dashboard.id),
              dashboard: dashboard,
              activeAccountName: activeAccountName,
              api: api,
            );
          });
          Navigator.pop(context);
        },
        queriesSelected: () {
          setState(() {
            _mainViewScaffold = QueryListScaffold(
              activeAccountName: activeAccountName,
              api: api,
              influxDBQueries: influxDBQueries,
              variables: variables,
            );
          });
          Navigator.pop(context);
        },
        tasksSelected: (List<InfluxDBTask> tasks) {
          _mainViewScaffold = TaskListScaffold(
            api: api,
            tasks: tasks,
            activeAccountName: activeAccountName,
          );
          Navigator.pop(context);
          setState(() {});
        },
        bucketsSelected: () {
          _mainViewScaffold = BucketListScaffold(
            activeAccountName: activeAccountName,
            api: api,
          );
          Navigator.pop(context);
          setState(() {});
        },
        api: api,
        variables: variables,
      ),
      appBar: AppBar(
        title: Text("Jigowatt"),
        actions: [
          IconButton(
              icon: Icon(Icons.account_circle_rounded),
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (BuildContext context) {
                    return AccountListScaffold(
                      accountDocs: accountDocs,
                      onActiveAccountChanged: (Document activeAccountDoc) {
                        onActiveAccountChanged(activeAccountDoc);
                      },
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

  Widget _mainViewScaffold;

  Widget mainBody() {
    if (accountDocs.documentsLoaded && accountDocs.length == 0) {
      return Center(
        child: FirstRunWidget(
          accountDocs: accountDocs,
          onActiveAccountChanged: (Document newAccount) {
            onActiveAccountChanged(newAccount);
          },
        ),
      );
    }
    if (_accountReadyState == AccountReadyState.InProgress) {
      return Center(
        child: CircularProgressIndicator(),
      );
    }
    if (_accountReadyState == AccountReadyState.Ready) {
      return _mainViewScaffold;
    }
    return Container();
  }
}

class FirstRunWidget extends StatelessWidget {
  final Function onActiveAccountChanged;
  final DocumentList accountDocs;

  const FirstRunWidget({
    Key key,
    @required this.onActiveAccountChanged,
    @required this.accountDocs,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              "Welcome to Jigowatt",
              style: Theme.of(context).textTheme.headline4,
              textAlign: TextAlign.center,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              "Jigowatt is an Open Source Client for InfluxDB 2.0, and requires at least one InfluxDB account. To get started, click the button below to add an existing InfluxDB account.",
              textAlign: TextAlign.center,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: RaisedButton(
              onPressed: () async {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (BuildContext context) {
                      return AccountScaffold(
                        onOK: (Document newAccount) {
                          accountDocs.add(newAccount);
                          onActiveAccountChanged(newAccount);
                        },
                      );
                    },
                  ),
                );
              },
              color: Theme.of(context).colorScheme.primary,
              child: Icon(
                Icons.person_add,
                size: 75.0,
                // color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              "You will need your Org ID, the URL for your account, and an all access token.",
              textAlign: TextAlign.center,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text("Jigowatt also requires permssions to access your device's storage to securely store your account information."),
          )
        ],
      ),
    );
  }
}

enum AccountReadyState { None, InProgress, Ready }
