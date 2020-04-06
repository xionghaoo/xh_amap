import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:xhamap/amap_location_service.dart';
import 'package:xhamap/amap_service.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  AmapLocationService _amapLocationService;

  @override
  void initState() {
    super.initState();
    AmapInitializer.setApiKey(androidKey: "10d6495de31a6f5336edfa81fa35881d", iosKey: "38611217b2ccd1f918d50fc70e0a8dd4");
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
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
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
