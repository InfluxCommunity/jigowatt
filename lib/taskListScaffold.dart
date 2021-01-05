import 'package:flutter/material.dart';
import 'package:flux_mobile/influxDB.dart';
import 'package:jigowatt/taskScaffold.dart';

class TaskListScaffold extends StatelessWidget {
  final List<InfluxDBTask> tasks;
  final String activeAccountName;
  const TaskListScaffold(
      {Key key, @required this.tasks, @required this.activeAccountName})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Icon(Icons.work),
        title: Column(
          children: [
            Text("Tasks"),
            Text(activeAccountName,
                style: Theme.of(context).textTheme.subtitle1),
          ],
        ),
      ),
      body: ListView.builder(
        itemCount: tasks.length,
        itemBuilder: (BuildContext context, int index) {
          return ListTile(
            title: Text(tasks[index].name),
            subtitle: Text("Runs every ${tasks[index].every}"),
            leading: tasks[index].active
                ? Icon(Icons.play_arrow)
                : Icon(Icons.play_disabled),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (BuildContext context) {
                  return TaskScaffold(
                    task: tasks[index],
                    activeAccountName: activeAccountName,
                  );
                }),
              );
            },
          );
        },
      ),
    );
  }
}
