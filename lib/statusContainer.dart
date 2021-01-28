import 'package:flutter/material.dart';
import 'package:flux_mobile/influxDB.dart';
import 'package:intl/intl.dart';

class StatusContainer extends StatefulWidget {
  final InfluxDBAPI api;
  final String activeAccountName;

  const StatusContainer(
      {Key key, @required this.api, @required this.activeAccountName})
      : super(key: key);
  @override
  _StatusContainerState createState() => _StatusContainerState();
}

class _StatusContainerState extends State<StatusContainer> {
  List<InfluxDBCheckStatus> _statuses;
  bool _sortAscending = true;
  int _sortColumn = 0;

  @override
  void initState() {
    _setStatus();
    super.initState();
  }

  void _setStatus() {
    widget.api.status(lastOnly: true).then((value) {
      setState(() {
        _statuses = value;
      });
    });
  }

  @override
  Widget build(Object context) {
    return _statuses == null
        ? Center(child: CircularProgressIndicator())
        : _statuses.length == 0
            ? Center(
                child: Text("No Statuses"),
              )
            : RefreshIndicator(
                onRefresh: () async {
                  _setStatus();
                },
                child: ListView(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        "Status",
                        style: Theme.of(context).textTheme.headline4,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Text(
                      widget.activeAccountName,
                      style: Theme.of(context).textTheme.headline5,
                      textAlign: TextAlign.center,
                    ),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        sortAscending: _sortAscending,
                        sortColumnIndex: _sortColumn,
                        columns: _columns(),
                        rows: _rows(),
                      ),
                    )
                  ],
                ),
              );
  }

  List<DataColumn> _columns() {
    List<DataColumn> cols = [];
    cols.addAll([
      DataColumn(
          label: Text("Status"),
          onSort: (columnIndex, ascending) {
            if (columnIndex == 0) {
              _statuses.sort((a, b) {
                if (ascending) {
                  return a.level.compareTo(b.level);
                } else {
                  return b.level.compareTo(a.level);
                }
              });
              setState(() {
                _sortAscending = !_sortAscending;
                _sortColumn = columnIndex;
              });
            }
          }),
      DataColumn(
        label: Text("When"),
        onSort: (columnIndex, ascending) {
          if (columnIndex == 1) {
            _statuses.sort((a, b) {
              if (a.time.isAtSameMomentAs(b.time)) return 0;
              bool isBefore = a.time.isBefore(b.time);
              if (isBefore && ascending) return -1;
              return 1;
            });
          }
          setState(() {
            _sortAscending = !_sortAscending;
            _sortColumn = columnIndex;
          });
        },
      ),
      DataColumn(
        label: Text("Message"),
        onSort: (columnIndex, ascending) {
          if (columnIndex == 2) {
            _statuses.sort((a, b) {
              if (ascending) {
                return a.message.compareTo(b.message);
              } else {
                return b.message.compareTo(a.message);
              }
            });
          }
          setState(() {
            _sortAscending = !_sortAscending;
            _sortColumn = columnIndex;
          });
        },
      ),
    ]);
    return cols;
  }

  List<DataRow> _rows() {
    List<DataRow> rows = [];
    _statuses.forEach((InfluxDBCheckStatus status) {
      List<DataCell> cells = [];
      cells.add(DataCell(LevelIcons[status.level]));
      cells.add(DataCell(
        Container(
          width: 80.0,
          child: Column(
            children: [
              Text(
                "${DateFormat("E").format(
                  status.time.toLocal(),
                )}",
              ),
              Text(
                "${DateFormat("jm").format(
                  status.time.toLocal(),
                )}",
              ),
            ],
          ),
        ),
      ));
      cells.add(
        DataCell(
          Text(status.message),
        ),
      );
      rows.add(
        DataRow(cells: cells),
      );
    });
    return rows;
  }

  List<String> _getKeys() {
    List<String> keys = ["Status", "Time", "Message"];
    _statuses.forEach((InfluxDBCheckStatus status) {
      status.additionalInfo.forEach((key, value) {
        if (!keys.contains(key)) {
          keys.add(key);
        }
      });
    });
    return keys;
  }

  List<Map<String, dynamic>> _getRows() {
    List<Map<String, dynamic>> rows = [];
    _statuses.forEach((InfluxDBCheckStatus status) {
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
    return Expanded(
      child: Container(
        child: SingleChildScrollView(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: keys.map((String key) {
                return DataColumn(
                  label: Text(key),
                  onSort: (columnIndex, ascending) {
                    rows.sort((a, b) => ascending
                        ? int.parse(a[key]).compareTo(int.parse(b[key]))
                        : int.parse(b[key]).compareTo(int.parse(a[key])));
                  },
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
