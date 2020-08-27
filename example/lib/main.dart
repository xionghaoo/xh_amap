import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:xhamap/amap_location_service.dart';
import 'package:xhamap/amap_service.dart';
import 'package:xhamap/amap_view.dart';
import 'package:xhamap/amap_param.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  AmapLocationService _amapLocationService;
  final _controller = AMapController();

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
        body: Container(
          child: AmapView(
            controller: _controller,
            onMarkerClick: (index, distance) {
//              _showMerchantDetail(storeMap[index], index, distance);
            },
            param: AmapParam(
                initialCenterPoint: [22.630019, 114.068159],
                enableMyMarker: true,
                mapType: AmapParam.routeMap,
//                merchantAddressList: merchantAddresses
                  merchantAddressList: [
                    // 114.038225,22.618959
                    AddressInfo(GeoPoint(22.618959, 114.038225), "Pos1", index: 1, indexName: "1"),
                    // 114.109808,22.568798 麦德龙
                    AddressInfo(GeoPoint(22.568798, 114.109808), "Pos2", index: 2, indexName: "2"),
                    // 114.060541,22.529242
                    AddressInfo(GeoPoint(22.529242, 114.060541), "Pos3", index: 3, indexName: "3"),
                    // 114.087063,22.548665 华新
                    AddressInfo(GeoPoint(22.525982, 113.93569), "Pos4", index: 4, indexName: "4"),
                  ],
//                      startAddressList: [
//                        // 114.038225,22.618959
//                        AddressInfo(GeoPoint(22.618959, 114.038225), "起点"),
//                        // 114.109808,22.568798 麦德龙
//                        AddressInfo(GeoPoint(22.568798, 114.109808), "起点"),
//                      ],
//                      endAddressList: [
//                        // 114.060541,22.529242
//                        AddressInfo(GeoPoint(22.529242, 114.060541), "终点"),
//                        // 114.087063,22.548665 华新
//                        AddressInfo(GeoPoint(22.548665, 114.087063), "终点"),
//                      ]
            ),
          ),
        ),
      ),
    );
  }
}
