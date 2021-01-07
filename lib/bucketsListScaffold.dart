import 'package:flutter/material.dart';
import 'package:flux_mobile/influxDB.dart';
import 'package:jigowatt/bucketScaffold.dart';
import 'my_flutter_app_icons.dart';

class BucketListScaffold extends StatefulWidget {
  final List<InfluxDBBucket> buckets;
  final InfluxDBAPI api;
  final String activeAccountName;

  const BucketListScaffold(
      {Key key, @required this.buckets, this.api, this.activeAccountName})
      : super(key: key);

  @override
  _BucketListScaffoldState createState() => _BucketListScaffoldState();
}

class _BucketListScaffoldState extends State<BucketListScaffold> {
  bool refreshing = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Icon(MyFlutterApp.disks_nav),
        title: Column(
          children: [
            Text("Buckets"),
            Text(widget.activeAccountName,
                style: Theme.of(context).textTheme.subtitle1),
          ],
        ),
      ),
      body: refreshing ? Center(child: CircularProgressIndicator()) : RefreshIndicator(
        onRefresh: () async {
          refreshing = true;
          widget.buckets.forEach((InfluxDBBucket bucket) async {
            setState(() async {
              await bucket.refresh();
            });
          });
          setState(() {
            refreshing = false;
          });
        },
        child: ListView.builder(
            itemCount: widget.buckets.length,
            itemBuilder: (BuildContext builder, int index) {
              String subtitle = "";
              if (widget.buckets[index].mostRecentWrite == null) {
                subtitle += "Empty";
              } else {
                Duration dur = DateTime.now()
                    .difference(widget.buckets[index].mostRecentWrite);
                String ago = "";
                if (dur.inMinutes < 2) {
                  ago = "Last written just now";
                } else if (dur.inMinutes < 60) {
                  ago = "Last written ${dur.inMinutes.toString()} minutes ago";
                } else if (dur.inHours < 24) {
                  ago = "Last written ${dur.inHours} hours ago";
                } else {
                  ago = "Last written ${dur.inDays} days ago";
                }
                subtitle = ago;
              }
              return ListTile(
                title: Text(widget.buckets[index].name),
                subtitle: Text(subtitle),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (BuildContext context) {
                      return BucketScaffold(
                        bucket: widget.buckets[index],
                        api: widget.api,
                        activeAccountName: widget.activeAccountName,
                      );
                    }),
                  );
                },
              );
            }),
      ),
    );
  }
}
