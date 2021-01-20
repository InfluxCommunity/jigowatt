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
      _notificationRule.onLoadComplete = _onLoadComplete;
      _notificationRule.refresh();
    });

    widget.notificationRule.onLoadComplete = _onLoadComplete;
    _notificationRule = widget.notificationRule;
    super.initState();
  }

  _onLoadComplete() {
    setState(() {});
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
            _notificationRule.onLoadComplete = _onLoadComplete;
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

    widgets.add(
      RecentNotificationsWidget(notificationRule: _notificationRule),
    );

    widgets.add(Divider());
    widgets.add(
      RecentChecksWidget(notificationRule: _notificationRule),
    );
    return widgets;
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

class RecentNotificationsWidget extends StatelessWidget {
  final InfluxDBNotificationRule notificationRule;

  const RecentNotificationsWidget({
    Key key,
    @required this.notificationRule,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text("Notifications, Last 24h"),
      notificationRule.recentNotifications == null ||
              notificationRule.recentNotifications.length == 0
          ? Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off),
                  Text("None"),
                ],
              ),
            )
          : RecentsTable(
              keys: _getKeys(),
              rows: _getRows(),
            )
    ]);
  }

  List<String> _getKeys() {
    List<String> keys = ["Status", "Time", "End Point", "Message"];
    keys.addAll(notificationRule.recentNotifications[0].additionalInfo.keys);
    return keys;
  }

  List<Map<String, dynamic>> _getRows() {
    List<Map<String, dynamic>> rows = [];
    notificationRule.recentNotifications
        .forEach((InfluxDBNotification notification) {
      Map<String, dynamic> row = {
        "Status": notification.level,
        "Time": notification.time,
        "End Point": notification.notificationEndPoint,
        "Message": notification.message,
      };
      row.addAll(notification.additionalInfo);
      rows.add(row);
    });
    return rows;
  }
}

class RecentChecksWidget extends StatelessWidget {
  final InfluxDBNotificationRule notificationRule;

  const RecentChecksWidget({
    Key key,
    @required this.notificationRule,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text("Most Recent Check Statuses, Last 24h"),
        notificationRule.recentStatuses == null ||
                notificationRule.recentStatuses.length == 0
            ? Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.notifications_off),
                    Text("None"),
                  ],
                ),
              )
            : RecentsTable(keys: _getKeys(), rows: _getRows()),
      ],
    );
  }

  List<String> _getKeys() {
    List<String> keys = ["Status", "Time", "Message"];
    keys.addAll(notificationRule.recentStatuses[0].additionalInfo.keys);
    return keys;
  }

  List<Map<String, dynamic>> _getRows() {
    List<Map<String, dynamic>> rows = [];
    notificationRule.recentStatuses
        .forEach((InfluxDBCheckStatus status) {
      Map<String, dynamic> row = {
        "Status": status.level,
        "Time": status.time,
        "Message": status.message,
      };
      row.addAll(status.additionalInfo);
      rows.add(row);
    });
    return rows;
  }
}

class RecentsTable extends StatelessWidget {
  final List<String> keys;
  final List<Map<String, dynamic>> rows;

  const RecentsTable({Key key, @required this.keys, @required this.rows})
      : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 250.0,
      child: SingleChildScrollView(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: keys.map((String key) {
              return DataColumn(
                label: Text(key),
              );
            }).toList(),
            rows: rows.map((Map<String, dynamic> row) {
              return DataRow(
                cells: keys.map((String key) {
                  switch (key) {
                    case "Status":
                      return DataCell(LevelIcons[row["Status"]]);
                    case "Time":
                      return DataCell(
                        Container(
                          width: 80.0,
                          child: Column(
                            children: [
                              Text(
                                "${DateFormat("E").format(
                                  row["Time"].toLocal(),
                                )}",
                              ),
                              Text(
                                "${DateFormat("jm").format(
                                  row["Time"].toLocal(),
                                )}",
                              ),
                            ],
                          ),
                        ),
                      );
                    default:
                      return DataCell(
                        Text(
                          row[key].toString(),
                        ),
                      );
                  }
                }).toList(),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

const LevelIcons = {
  0: Icon(Icons.check, color: Colors.green),
  1: Icon(
    Icons.info,
    color: Colors.blue,
  ),
  2: Icon(
    Icons.warning,
    color: Colors.yellow,
  ),
  3: Icon(Icons.warning, color: Colors.red),
};
