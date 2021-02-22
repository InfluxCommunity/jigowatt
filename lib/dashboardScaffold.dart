import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flux_mobile/influxDB.dart';

import 'variablesDialog.dart';

class DashboardScaffold extends StatefulWidget {
  final InfluxDBAPI api;
  final InfluxDBDashboard dashboard;
  final String activeAccountName;

  const DashboardScaffold(
      {Key key,
      @required this.dashboard,
      @required this.activeAccountName,
      @required this.api})
      : super(key: key);

  @override
  _DashboardScaffoldState createState() => _DashboardScaffoldState();
}

class _DashboardScaffoldState extends State<DashboardScaffold> {
  InfluxDBDashboard _dashboard;
  String _dashboardId;
  @override
  void initState() {

    // Decided against automatically refreshing dashboards
    // but can just uncomment this to enable it
    // Timer.periodic(Duration(minutes: 1), (time) {
    //   _refreshDashboard();
    // });
    _dashboard = widget.dashboard;
    _dashboardId = _dashboard.id;
    _dashboard.onCellsUpdated = (() {
      setState(() {});
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () async {
              await showDialog(
                context: context,
                builder: (_) => VariablesDialog(
                  variables: widget.dashboard.variables,
                  onOK: _refreshDashboard,
                  referencedVariables: widget.dashboard.referencedVariableNames,
                ),
                barrierDismissible: false,
              );
            },
          )
        ],
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.dashboard.name),
            Text(
              widget.activeAccountName,
              style: TextStyle(fontSize: 12.0, fontWeight: FontWeight.bold),
            )
          ],
        ),
      ),
      body: _dashboard == null
          ? Center(
              child: CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh: _refreshDashboard,
              child: InfluxDBDashboardCellListView(
                dashboard: _dashboard,
              ),
            ),
    );
  }

  Future<void> _refreshDashboard() async {
    setState(() {
      _dashboard = null;
    });

    widget.api
        .dashboards(variables: widget.dashboard.variables)
        .then((List<InfluxDBDashboard> boards) {
      boards.forEach((InfluxDBDashboard board) {
        if (board.id == _dashboardId) {
          setState(() {
            _dashboard = board;
            _dashboard.onCellsUpdated = () {
              setState(() {});
            };
          });
        }
      });
    });
  }
}
