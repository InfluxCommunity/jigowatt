import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flux_mobile/influxDB.dart';
import 'package:jigowatt/bucketScaffold.dart';
import 'my_flutter_app_icons.dart';

class BucketListScaffold extends StatefulWidget {
  final InfluxDBAPI api;
  final String activeAccountName;

  const BucketListScaffold(
      {Key key, @required this.api, this.activeAccountName})
      : super(key: key);

  @override
  _BucketListScaffoldState createState() => _BucketListScaffoldState();
}

class _BucketListScaffoldState extends State<BucketListScaffold> {
  List<InfluxDBBucket> _buckets;

  @override
  void initState() {
    Timer.periodic(Duration(minutes: 1), (timer) { 
      setBuckets();
    });
    setBuckets();
    super.initState();
  }

  Future setBuckets() async {
    _buckets = await widget.api.buckets(onLoadComplete: () {
      setState(() {});
    });
    setState(() {});
  }

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
      body: _buckets == null
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                await setBuckets();
                return;
              },
              child: ListView.builder(
                  itemCount: _buckets.length,
                  itemBuilder: (BuildContext builder, int index) {
                    String subtitle = "";
                    if (_buckets[index].mostRecentWrite == null) {
                      subtitle += "Empty";
                    } else {
                      Duration dur = DateTime.now()
                          .difference(_buckets[index].mostRecentWrite);
                      String ago = "";
                      if (dur.inMinutes < 2) {
                        ago = "Last written just now";
                      } else if (dur.inMinutes < 60) {
                        ago =
                            "Last written ${dur.inMinutes.toString()} minutes ago";
                      } else if (dur.inHours < 24) {
                        ago = "Last written ${dur.inHours} hours ago";
                      } else {
                        ago = "Last written ${dur.inDays} days ago";
                      }
                      subtitle = ago;
                    }
                    return ListTile(
                      title: Text(_buckets[index].name),
                      subtitle: Text(subtitle),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (BuildContext context) {
                            return BucketScaffold(
                              bucket: _buckets[index],
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
