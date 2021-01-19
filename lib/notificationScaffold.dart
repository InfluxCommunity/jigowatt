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
  const RecentNotificationsWidget({
    Key key,
    @required InfluxDBNotificationRule notificationRule,
  }) : _notificationRule = notificationRule, super(key: key);

  final InfluxDBNotificationRule _notificationRule;

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text("Notifications, Last 24h"),
      _notificationRule.recentNotifications == null ||
              _notificationRule.recentNotifications.length == 0
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
          : NotificationsDataTable(
              notifications: _notificationRule.recentNotifications,
            )
    ]);
  }
}

class RecentChecksWidget extends StatelessWidget {
  const RecentChecksWidget({
    Key key,
    @required InfluxDBNotificationRule notificationRule,
  }) : _notificationRule = notificationRule, super(key: key);

  final InfluxDBNotificationRule _notificationRule;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text("Most Recent Check Statuses, Last 24h"),
        _notificationRule.recentStatuses == null ||
                _notificationRule.recentStatuses.length == 0
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
            : NotificationsDataTable(
                notifications: _notificationRule.recentStatuses,
              ),
      ],
    );
  }
}

class NotificationsDataTable extends StatelessWidget {
  final List<InfluxDBCheckStatus> notifications;

  const NotificationsDataTable({Key key, @required this.notifications})
      : super(key: key);
  @override
  Widget build(BuildContext context) {
    List<String> keys = ["Status", "Time", "Message"];
   
    
    notifications.forEach((notification) {
      notification.additionalInfo.keys.forEach((String key) {
        if (!keys.contains(key)) keys.add(key);
      });
    });

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
            rows: notifications.map((notification) {
              return DataRow(
                cells: keys.map((String key) {
                  switch (key) {
                    case "Status":
                      return DataCell(LevelIcons[notification.level]);
                    case "Time":
                      return DataCell(
                        Container(
                          width: 80.0,
                          child: Column(
                            children: [
                              Text(
                                "${DateFormat("E").format(
                                  notification.time.toLocal(),
                                )}",
                              ),
                              Text(
                                "${DateFormat("jm").format(
                                  notification.time.toLocal(),
                                )}",
                              ),
                            ],
                          ),
                        ),
                      );
                    case "Message":
                      return DataCell(
                        Text(
                          notification.message,
                        ),
                      );
                    default:
                      return DataCell(
                        Text(
                          notification.additionalInfo[key],
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
