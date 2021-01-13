import 'package:flutter/material.dart';
import 'package:flux_mobile/influxDB.dart';
import 'my_flutter_app_icons.dart';

class JigoWattDrawer extends StatelessWidget {
  final String activeAccountName;
  final List<InfluxDBDashboard> dashboards;
  final List<InfluxDBNotification> notifications;
  final Function dashboardSelected;
  final Function queriesSelected;
  final Function tasksSelected;
  final Function bucketsSelected;
  final Function notificationSelected;

  const JigoWattDrawer({
    Key key,
    @required this.activeAccountName,
    @required this.dashboards,
    @required this.dashboardSelected,
    @required this.queriesSelected,
    @required this.tasksSelected,
    @required this.bucketsSelected,
    @required this.notifications,
    @required this.notificationSelected,
  }) : super(key: key);

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
        onTap: queriesSelected,
      ),
    );

    widgets.add(Divider());
    widgets.add(
      ListTile(
        title: Text("Buckets"),
        leading: Icon(MyFlutterApp.disks_nav),
        subtitle: Text(activeAccountName),
        onTap: bucketsSelected,
      ),
    );

    widgets.add(Divider());
    widgets.add(
      ListTile(
        title: Text("Tasks"),
        leading: Icon(Icons.work),
        subtitle: Text(activeAccountName),
        onTap: tasksSelected,
      ),
    );

    if (notifications != null && notifications.length > 0) {
      widgets.add(Divider());
      widgets.add(
        ListTile(
          title: Text("NOTIFICATIONS"),
          leading: Icon(Icons.notifications),
          subtitle: Text(activeAccountName),
        ),
      );
      notifications.forEach((InfluxDBNotification notification) {
        Map<String, int> levels = {"ok": 0, "info": 1, "warn": 2, "crit": 3};
        int curLevel = 0;
        String subtitleString;
        if (notification.recentStatuses.length > 0) {
          subtitleString = notification.recentStatuses[0].rows[0]["_value"];
        }
        notification.recentStatuses.forEach((InfluxDBTable table) {
          if (levels[table.rows[0]["_level"]] > curLevel) {
            curLevel = table.rows[0]["_level"];
            subtitleString =
                table.rows[0]["_value"];
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
          subtitle: Text(
              subtitleString == null ? "no recent status" : subtitleString),
          onTap: () {
            notificationSelected(notification);
          },
        ));
      });
    }

    if (dashboards != null) {
      widgets.add(Divider());
      widgets.add(
        ListTile(
          title: Text("DASHBOARDS"),
          leading: Icon(Icons.dashboard),
          subtitle: Text(activeAccountName),
        ),
      );

      dashboards.forEach((InfluxDBDashboard dashboard) {
        widgets.add(ListTile(
          title: Text(dashboard.name),
          onTap: () {
            dashboardSelected(dashboard);
          },
        ));
      });
    }
    return widgets;
  }
}
