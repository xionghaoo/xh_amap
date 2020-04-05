import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:xhamap/xhamap.dart';
import 'package:xhamap/amap_location_service.dart';
import 'package:xhamap/amap_service.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _platformVersion = 'Unknown';

  AmapLocationService _amapLocationService;

  @override
  void initState() {
    super.initState();
    AmapInitializer.setApiKey(androidKey: "10d6495de31a6f5336edfa81fa35881d", iosKey: null);
    initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    String platformVersion;
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      platformVersion = await Xhamap.platformVersion;
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child: Column(
            children: <Widget>[
              Text('Running on: $_platformVersion\n'),
              RaisedButton(
                child: Text("启动定位服务"),
                onPressed: () {
                  AmapLocationService().start().then((_) {
                    AmapLocationService().startLocationStream().listen((data) {
                      print("received address: ${data['address']}, ${data['lat']}, ${data['lng']}");
                    });
                  });
                },
              )
            ],
          ),
        ),
      ),
    );
  }
}
