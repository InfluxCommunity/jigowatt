import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flux_mobile/influxDB.dart';
import 'package:intl/intl.dart';

class NotificationScaffold extends StatefulWidget {
  final InfluxDBNotificationRule notificationRule;
  final String activeAccountName;
  final InfluxDBAPI api;

  const NotificationScaffold(
      {Key key,
      @required this.notificationRule,
      @required this.activeAccountName,
      @required this.api})
      : super(key: key);

  @override
  _NotificationScaffoldState createState() => _NotificationScaffoldState();
}

class _NotificationScaffoldState extends State<NotificationScaffold> {
  InfluxDBNotificationRule _notificationRule;

  @override
  void initState() {
    Timer.periodic(Duration(minutes: 1), (timer) {
      _notificationRule.refresh();
    });
    _notificationRule = widget.notificationRule;
    _notificationRule.onLoadComplete = () {
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
            Text(_notificationRule.name),
            Text(widget.activeAccountName,
                style: Theme.of(context).textTheme.subtitle1),
          ],
        ),
      ),
      body: RefreshIndicator(
          onRefresh: () async {
            _notificationRule.refresh().then((value) {
              setState(() {});
            });
          },
          child: ListView(children: _buildChildren())),
    );
  }

  List<Widget> _buildChildren() {
    List<Widget> widgets = [];
    if (_notificationRule.description != null) {
      widgets.add(
        ListTile(
          title: (Text(
            _notificationRule.description,
          )),
        ),
      );
    }
    widgets.add(
      SwitchListTile(
          title: Text(_notificationRule.active ? "Active" : "Inactive"),
          value: _notificationRule.active,
          onChanged: (bool newVal) {
            _notificationRule
                .setEnabled(enabled: newVal)
                .then((bool returnedVal) {
              setState(() {});
            });
          }),
    );
    widgets.add(_lastRunTile());

    if (_notificationRule.errorString != null) {
      widgets.add(
        ListTile(
          title: Text(
            _notificationRule.errorString,
            style: TextStyle(color: Colors.red),
          ),
        ),
      );
    }
    widgets.add(Divider());
    if (_notificationRule.recentStatuses.length > 0) {
      widgets.add(
        ListTile(
            title: Text(
              _notificationRule.recentNotifications.last.time
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
            child: _notificationRule.recentStatuses.length < 1
                ? Center(
                    child: Text("No check statuses in last 24 hours"),
                  )
                : SingleChildScrollView(
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
                        rows: _notificationRule.recentStatuses
                            .map((InfluxDBCheckStatus status) {
                          return _getCheckDataRow(status);
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

  DataRow _getCheckDataRow(InfluxDBCheckStatus status) {
    Icon leadingIcon = Icon(Icons.check, color: Colors.green);
    switch (status.level) {
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
          DateFormat("jm").format(
            status.time.toLocal(),
          ),
        ),
      ),
      DataCell(Text(
        status.message,
      ))
    ]);
  }

  ListTile _lastRunTile() {
    Icon statusIcon;
    String statusString = "";
    switch (_notificationRule.lastRunSucceeded) {
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
        title: Text(_notificationRule.latestCompleted.toLocal().toString()),
        subtitle: Text(statusString),
        leading: statusIcon);
  }
}
