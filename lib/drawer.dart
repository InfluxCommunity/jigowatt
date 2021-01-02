import 'package:flutter/material.dart';
import 'package:flux_mobile/influxDB.dart';

class JigoWattDrawer extends StatelessWidget {
  final String activeAccountName;
  final List<InfluxDBDashboard> dashboards;
  final Function dashboardSelected;
  final Function queriesSelected;
  
  const JigoWattDrawer({
    Key key,
    @required this.activeAccountName,
    @required this.dashboards,
    @required this.dashboardSelected, @required this.queriesSelected,
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
