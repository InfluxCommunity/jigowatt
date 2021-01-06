import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flux_mobile/influxDB.dart';

class BucketScaffold extends StatefulWidget {
  final InfluxDBBucket bucket;
  final InfluxDBAPI api;
  final String activeAccountName;

  const BucketScaffold(
      {Key key,
      @required this.bucket,
      @required this.api,
      @required this.activeAccountName})
      : super(key: key);

  @override
  _BucketScaffoldState createState() => _BucketScaffoldState();
}

class _BucketScaffoldState extends State<BucketScaffold> {
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
    if (widget.bucket.hasRetentionPolicy) {
      widgets.add(
        ListTile(
          title:
              Text("Retention: ${widget.bucket.retentionSeconds / 86400} days"),
        ),
      );
    } else {
      widgets.add(
        ListTile(
          title: Text("Retention: Forever"),
        ),
      );
    }
    widgets.add(
      ListTile(
        title: Text("Total Cardinality: ${widget.bucket.cardinality}"),
      ),
    );
    if (widget.bucket.mostRecentWrite != null) {
      widgets.add(MeasurementsWidget(api: widget.api, bucket: widget.bucket));
    }
    if (widget.bucket.mostRecentRecord != null) {
      widget.bucket.mostRecentRecord.keys.remove("_time");
      widget.bucket.mostRecentRecord.rows[0].remove("_time");
      widgets.add(
        Divider(),
      );
      widgets.add(Container(
        child: Column(
          children: [
            Text(
              "Most Recent Record Written",
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headline6,
            ),
            Text(
              widget.bucket.mostRecentWrite.toLocal().toString(),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.caption,
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Table(
                children: widget.bucket.mostRecentRecord.keys.map((String key) {
                  return TableRow(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          key,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(widget.bucket.mostRecentRecord.rows[0][key]
                            .toString()),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ));
    }

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

  @override
  void initState() {
    String flux = """
import "influxdata/influxdb"
import "influxdata/influxdb/schema"


schema.measurements(bucket: \"${widget.bucket.name}\")
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
                    style: Theme.of(context).textTheme.headline6,
                  ),
                  Table(
                    children: _table.rows.map((InfluxDBRow row) {
                      return TableRow(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(row["measurement"],
                                textAlign: TextAlign.right,
                                style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(row["cardinality"].toString()),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          );
  }
}
