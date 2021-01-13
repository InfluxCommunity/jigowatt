import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flux_mobile/influxDB.dart';
import 'package:intl/intl.dart';

class NotificationScaffold extends StatefulWidget {
  final InfluxDBNotification notification;
  final String activeAccountName;
  final InfluxDBAPI api;

  const NotificationScaffold(
      {Key key,
      @required this.notification,
      @required this.activeAccountName,
      @required this.api})
      : super(key: key);

  @override
  _NotificationScaffoldState createState() => _NotificationScaffoldState();
}

class _NotificationScaffoldState extends State<NotificationScaffold> {
  InfluxDBNotification _notification;

  @override
  void initState() {
    Timer.periodic(Duration(minutes: 1), (timer) {
      _notification.refresh();
    });
    _notification = widget.notification;
    _notification.onLoadComplete = () {
      setState(() {});
    };
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Icon(Icons.notifications),
        title: Column(
          children: [
            Text(_notification.name),
            Text(widget.activeAccountName,
                style: Theme.of(context).textTheme.subtitle1),
          ],
        ),
      ),
      body: RefreshIndicator(
          onRefresh: () async {
            _notification.refresh().then((value) {
              setState(() {});
            });
          },
          child: ListView(children: _buildChildren())),
    );
  }

  List<Widget> _buildChildren() {
    List<Widget> widgets = [];
    if (_notification.description != null) {
      widgets.add(
        ListTile(
          title: (Text(
            _notification.description,
          )),
        ),
      );
    }
    widgets.add(
      SwitchListTile(
          title: Text(_notification.active ? "Active" : "Inactive"),
          value: _notification.active,
          onChanged: (bool newVal) {
            _notification.setEnabled(enabled: newVal).then((bool returnedVal) {
              setState(() {});
            });
          }),
    );
    widgets.add(_lastRunTile());

    if (_notification.errorString != null) {
      widgets.add(
        ListTile(
          title: Text(
            _notification.errorString,
            style: TextStyle(color: Colors.red),
          ),
        ),
      );
    }
    widgets.add(Divider());
    if (_notification.mostRecentNotification.rows.length > 0) {
      widgets.add(
        ListTile(
            title: Text(
              DateTime.parse(
                      _notification.mostRecentNotification.rows[0]["_time"])
                  .toLocal()
                  .toString(),
            ),
            subtitle: Text("Most Recent Notification"),
            leading: Icon(Icons.notifications)),
      );
    } else {
      widgets.add(ListTile(
          title: Text(
            "No Recent Notifications",
          ),
          leading: Icon(Icons.notifications_off)));
    }
    widgets.add(Divider());
    widgets.add(
      Column(
        children: [
          Text("Most Recent Checks"),
          Container(
            height: 300.0,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SingleChildScrollView(
                child: DataTable(
                  columns: [
                    DataColumn(
                      label: Text("Status"),
                    ),
                    DataColumn(
                      label: Text("Time"),
                    ),
                    DataColumn(
                      label: Text("Message"),
                    )
                  ],
                  rows: _notification.recentStatuses.map((InfluxDBTable table) {
                    return _getCheckDataRow(table);
                  }).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
    return widgets;
  }

  DataRow _getCheckDataRow(InfluxDBTable status) {
    Map<String, int> levels = {"ok": 0, "info": 1, "warn": 2, "crit": 3};
    int curLevel = 0;

    _notification.recentStatuses.forEach((InfluxDBTable table) {
      if (levels[status.rows[0]["_level"]] > curLevel) {
        curLevel = status.rows[0]["_level"];
      }
    });
    Icon leadingIcon = Icon(Icons.check, color: Colors.green);
    switch (curLevel) {
      case 1:
        leadingIcon = Icon(
          Icons.info,
          color: Colors.blue,
        );
        break;
      case 2:
        leadingIcon = Icon(
          Icons.warning,
          color: Colors.yellow,
        );
        break;
      case 3:
        leadingIcon = Icon(Icons.warning, color: Colors.red);
        break;
    }
    return DataRow(cells: [
      DataCell(
        leadingIcon,
      ),
      DataCell(
        Text(
          DateFormat("jm")
              .format(DateTime.parse(status.rows[0]["_time"]).toLocal()),
        ),
      ),
      DataCell(
        Text(status.rows[0]["_value"]),
      )
    ]);
  }

  ListTile _lastRunTile() {
    Icon statusIcon;
    String statusString = "";
    switch (_notification.lastRunSucceeded) {
      case TaskSuccess.Canceled:
        statusIcon = Icon(
          Icons.cancel,
          color: Colors.yellow,
        );
        statusString = "Last run was cancelled";
        break;
      case TaskSuccess.Failed:
        statusIcon = Icon(
          Icons.error,
          color: Colors.red,
        );
        statusString = "Last run failed";
        break;
      case TaskSuccess.Succeeded:
        statusIcon = Icon(
          Icons.check,
          color: Colors.green,
        );
        statusString = "Last run succeeded";
        break;
    }
    return ListTile(
        title: Text(_notification.latestCompleted.toLocal().toString()),
        subtitle: Text(statusString),
        leading: statusIcon);
  }
}
