import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flux_mobile/influxDB.dart';
import 'my_flutter_app_icons.dart';

class JigoWattDrawer extends StatefulWidget {
  final String activeAccountName;
  final Function dashboardSelected;
  final Function queriesSelected;
  final Function tasksSelected;
  final Function bucketsSelected;
  final Function notificationSelected;
  final InfluxDBAPI api;
  final InfluxDBVariablesList variables;

  const JigoWattDrawer({
    Key key,
    @required this.activeAccountName,
    @required this.dashboardSelected,
    @required this.queriesSelected,
    @required this.tasksSelected,
    @required this.bucketsSelected,
    @required this.notificationSelected,
    @required this.api,
    @required this.variables,
  }) : super(key: key);

  @override
  _JigoWattDrawerState createState() => _JigoWattDrawerState();
}

class _JigoWattDrawerState extends State<JigoWattDrawer> {
  List<InfluxDBDashboard> dashboards;
  List<InfluxDBTask> tasks;
  List<InfluxDBNotification> notifications;

  @override
  void initState() {
    Timer.periodic(Duration(minutes: 1), (Timer t) {
      _setEntities();
    });

    _setEntities();
    super.initState();
  }

  _setEntities() async {
    List<dynamic> futures = await Future.wait<dynamic>([
      widget.api.tasks(),
      widget.api.notifications(),
      widget.api.dashboards(variables: widget.variables),
    ]);

    tasks = futures[0];
    notifications = futures[1];
    dashboards = futures[2];

    notifications.forEach((InfluxDBNotification notification) {
      notification.onLoadComplete = () {
        setState(() {});
      };
    });

    dashboards.forEach((InfluxDBDashboard dashboard) {
      dashboard.onCellsUpdated = () {
        setState(() {});
      };
    });
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.85,
      child: Scaffold(
        appBar: AppBar(
          title: Text("Jigowatt"),
        ),
        body: ListView(
          children: drawerChildren(),
          shrinkWrap: true,
        ),
      ),
    );
  }

  List<Widget> drawerChildren() {
    List<Widget> widgets = [];
    widgets.add(
      ListTile(
        title: Text("Queries"),
        leading: Icon(Icons.code),
        onTap: widget.queriesSelected,
      ),
    );

    widgets.add(Divider());
    widgets.add(
      ListTile(
        title: Text("Buckets"),
        leading: Icon(MyFlutterApp.disks_nav),
        subtitle: Text(widget.activeAccountName),
        onTap: widget.bucketsSelected,
      ),
    );

    widgets.add(Divider());
    widgets.add(
      ListTile(
        title: Text("Tasks"),
        leading: Icon(Icons.work),
        subtitle: Text(widget.activeAccountName),
        onTap: () {
          widget.tasksSelected(tasks);
        },
      ),
    );

    if (notifications != null && notifications.length > 0) {
      widgets.add(Divider());
      widgets.add(
        ListTile(
          title: Text("NOTIFICATIONS"),
          leading: Icon(Icons.notifications),
          subtitle: Text(widget.activeAccountName),
        ),
      );
      notifications.forEach((InfluxDBNotification notification) {
        notification.onLoadComplete = () {
          setState(() {});
        };
        if (notification.recentStatuses != null) {
          Map<String, int> levels = {"ok": 0, "info": 1, "warn": 2, "crit": 3};
          int curLevel = 0;

          notification.recentStatuses.forEach((InfluxDBTable table) {
            if (levels[table.rows[0]["_level"]] > curLevel) {
              curLevel = table.rows[0]["_level"];
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

          widgets.add(ListTile(
            leading: leadingIcon,
            title: Text(notification.name),
            subtitle: Text(notification.active ? "Active" : "Inactive"),
            onTap: () {
              widget.notificationSelected(notification);
            },
          ));
        }
      });
    }

    if (dashboards != null) {
      widgets.add(Divider());
      widgets.add(
        ListTile(
          title: Text("DASHBOARDS"),
          leading: Icon(Icons.dashboard),
          subtitle: Text(widget.activeAccountName),
        ),
      );

      dashboards.forEach((InfluxDBDashboard dashboard) {
        widgets.add(ListTile(
          title: Text(dashboard.name),
          onTap: () {
            widget.dashboardSelected(dashboard);
          },
        ));
      });
    }
    return widgets;
  }
}
