import 'package:flutter/material.dart';
import 'package:flux_mobile/influxDB.dart';

class TaskScaffold extends StatefulWidget {
  final InfluxDBTask task;
  final String activeAccountName;

  const TaskScaffold(
      {Key key, @required this.task, @required this.activeAccountName})
      : super(key: key);

  @override
  _TaskScaffoldState createState() => _TaskScaffoldState();
}

class _TaskScaffoldState extends State<TaskScaffold> {
  @override
  Widget build(BuildContext context) {
    Icon statusIcon;
    String statusString = "";
    switch (widget.task.lastRunSucceeded) {
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

    return Scaffold(
      appBar: AppBar(
        leading: Icon(Icons.work),
        title: Column(
          children: [
            Text(widget.task.name),
            Text(widget.activeAccountName,
                style: Theme.of(context).textTheme.subtitle1),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await widget.task.refresh();
          setState(() {});
        },
        child: ListView(
          children: [
            SwitchListTile(
              value: widget.task.active,
              title: Text(widget.task.active ? "Active" : "Inactive"),
              onChanged: (bool newVal) {
                widget.task.setEnabled(enabled: newVal).then((bool val) {
                  setState(() {});
                });
              },
            ),
            ListTile(
              leading: statusIcon,
              title: Text(widget.task.latestCompleted.toLocal().toString()),
              subtitle: Text(statusString),
            ),
            ErrorTile(task: widget.task),
            ListTile(
              title: TextField(
                decoration: InputDecoration(labelText: "Query"),
                readOnly: true,
                maxLines: 15,
                controller:
                    TextEditingController(text: widget.task.queryString),
                style: TextStyle(fontSize: 12.0, fontFamily: "monospace"),
              ),
            ),
            ListTile(
              leading: Icon(Icons.timer),
              title: Text("Runs every ${widget.task.every}"),
            ),
            ListTile(
              leading: Icon(Icons.access_time),
              title: Text(widget.task.offset == null
                  ? "No offset"
                  : "Offset ${widget.task.offset}"),
            ),
            ListTile(
              leading: Icon(
                Icons.calendar_today,
              ),
              title: Text(widget.task.updatedAt != null
                  ? widget.task.updatedAt.toLocal().toString()
                  : ""),
                  subtitle: Text("Last Updated"),
            ),
                        ListTile(
              leading: Icon(
                Icons.calendar_today,
              ),
              title: Text(widget.task.createdAt != null
                  ? widget.task.createdAt .toLocal().toString()
                  : ""),
                  subtitle: Text("Creation Date"),
            ),
          ],
        ),
      ),
    );
  }
}

class ErrorTile extends StatelessWidget {
  final InfluxDBTask task;

  const ErrorTile({Key key, @required this.task}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (task.errorString != null) {
      return ListTile(
        title: Text(
          task.errorString,
          style: TextStyle(color: Colors.red),
        ),
      );
    } else {
      return Divider();
    }
  }
}
