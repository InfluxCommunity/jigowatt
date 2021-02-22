import 'package:flutter/material.dart';
import 'package:flux_mobile/influxDB.dart';
import 'package:jigowatt/taskScaffold.dart';

class TaskListScaffold extends StatefulWidget {
  final List<InfluxDBTask> tasks;
  final String activeAccountName;
  final InfluxDBAPI api;
  const TaskListScaffold(
      {Key key,
      @required this.tasks,
      @required this.activeAccountName,
      @required this.api})
      : super(key: key);

  @override
  _TaskListScaffoldState createState() => _TaskListScaffoldState();
}

class _TaskListScaffoldState extends State<TaskListScaffold> {
  List<InfluxDBTask> _tasks;

  @override
  void initState() {
    _tasks = widget.tasks;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            Text("Tasks"),
            Text(widget.activeAccountName,
                style: Theme.of(context).textTheme.subtitle1),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _tasks = await widget.api.tasks();
          setState(() {});
        },
        child: ListView.builder(
          itemCount: _tasks.length,
          itemBuilder: (BuildContext context, int index) {
            return ListTile(
              title: Text(_tasks[index].name),
              subtitle: Text("Runs every ${_tasks[index].every}"),
              leading: _tasks[index].active
                  ? Icon(Icons.play_arrow)
                  : Icon(Icons.play_disabled),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (BuildContext context) {
                    return TaskScaffold(
                      task: _tasks[index],
                      activeAccountName: widget.activeAccountName,
                    );
                  }),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
