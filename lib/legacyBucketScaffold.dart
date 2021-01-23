import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flux_mobile/influxDB.dart';

class LegacyBucketScaffold extends StatefulWidget {
  final InfluxDBBucket bucket;
  final InfluxDBAPI api;
  final String activeAccountName;

  const LegacyBucketScaffold(
      {Key key,
      @required this.bucket,
      @required this.api,
      @required this.activeAccountName})
      : super(key: key);

  @override
  _LegacyBucketScaffoldState createState() => _LegacyBucketScaffoldState();
}

class _LegacyBucketScaffoldState extends State<LegacyBucketScaffold> {
  @override
  void initState() {
    widget.bucket.onLoadComplete = () {
      setState(() {});
    };
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            Text(widget.bucket.name),
            Text(widget.activeAccountName,
                style: Theme.of(context).textTheme.subtitle1),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await this.widget.bucket.refresh();
          setState(() {});
        },
        child: ListView(
          children: buildChildren(),
        ),
      ),
    );
  }

  List<Widget> buildChildren() {
    List<Widget> widgets = [];

    widgets.add(
      ListTile(
        title: Text(widget.bucket.hasRetentionPolicy
            ? "${widget.bucket.retentionSeconds / 86400} days"
            : "Forever"),
        subtitle: Text("Retention"),
      ),
    );

    return widgets;
  }
}

class MeasurementsWidget extends StatefulWidget {
  final InfluxDBAPI api;
  final InfluxDBBucket bucket;

  const MeasurementsWidget({Key key, @required this.api, @required this.bucket})
      : super(key: key);
  @override
  _MeasurementsWidgetState createState() => _MeasurementsWidgetState();
}

class _MeasurementsWidgetState extends State<MeasurementsWidget> {
  InfluxDBTable _table;
  Timer _timer;

  @override
  void initState() {
    _timer = Timer.periodic(Duration(minutes: 1), (timer) {
      widget.bucket.refresh().then((value) {
        setState(() {});
      });
    });
    String flux = """
import "influxdata/influxdb"
import "influxdata/influxdb/schema"


schema.tagValues(bucket: \"${widget.bucket.name}\", tag: "_measurement", start: -100y)
  |> map(fn: (r) => {
      m = r._value
      return {
        bucket: \"${widget.bucket.name}\",
        measurement: m,
        _value: (influxdb.cardinality(bucket: \"${widget.bucket.name}\", start: -100y, predicate: (r) => r._measurement == m) |> findRecord(idx:0, fn:(key) => true))._value
      }
    })
  |> sort(desc:true)
  |> drop(columns: ["bucket"])
  |> rename(columns: {_value: "cardinality"})
    """;
    InfluxDBQuery query = InfluxDBQuery(queryString: flux, api: widget.api);
    query.execute().then((List<InfluxDBTable> tables) {
      setState(() {
        _table = tables[0];
      });
    });
    super.initState();
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _table == null
        ? Center(
            child: CircularProgressIndicator(),
          )
        : Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              child: Column(
                children: [
                  Text(
                    "Cardinality By Measurement",
                    textAlign: TextAlign.center,
                  ),
                  DataTable(
                    columns: [
                      DataColumn(
                        label: Text("Measurement"),
                      ),
                      DataColumn(
                        label: Text(
                          "Cardinality",
                        ),
                      ),
                    ],
                    rows: _table.rows.map((InfluxDBRow row) {
                      return DataRow(cells: [
                        DataCell(
                          Text(
                            row["measurement"],
                          ),
                        ),
                        DataCell(
                          Text(
                            row["cardinality"].toString(),
                          ),
                        ),
                      ]);
                    }).toList(),
                  )
                ],
              ),
            ),
          );
  }
}
