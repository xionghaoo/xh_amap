import 'package:flutter/material.dart';
import 'package:xhamap/amap_location_service.dart';
import 'package:xhamap/amap_service.dart';
import 'package:xhamap/amap_view.dart';
import 'package:xhamap/amap_param.dart';

class AddressSelectPage extends StatefulWidget {
  @override
  _AddressSelectPageState createState() => _AddressSelectPageState();
}

class _AddressSelectPageState extends State<AddressSelectPage> {

  final _controller = AMapController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("地址选择"),),
      body: Stack(
        children: [
          AmapView(
            controller: _controller,
            onMarkerClick: (index, distance) {
              print("marker: index = $index, distance: $distance");
            },
            onMapZoom: (zoom) {
              print("zoom level: $zoom");
              switch (zoom) {
                case 0:
                  _controller.updateMarkers([
                    // 114.038225,22.618959
                    AddressInfo(GeoPoint(22.618959, 114.038225), "Pos1", index: 1, indexName: "1", showType: 0),
                    // 114.109808,22.568798 麦德龙
                    AddressInfo(GeoPoint(22.568798, 114.109808), "Pos2", index: 2, indexName: "2", showType: 0),
                    // 114.060541,22.529242
                    AddressInfo(GeoPoint(22.529242, 114.060541), "Pos3", index: 3, indexName: "3", showType: 0),
                    // 114.087063,22.548665 华新
                    AddressInfo(GeoPoint(22.525982, 113.93569), "Pos4", index: 4, indexName: "4", showType: 0),
                  ]);
                  break;
                case 1:
                  _controller.updateMarkers([
                    AddressInfo(GeoPoint(22.618959, 114.038225), "Pos1", index: 1, indexName: "1", showType: 1),
                    // 114.109808,22.568798 麦德龙
                    AddressInfo(GeoPoint(22.568798, 114.109808), "Pos2", index: 2, indexName: "2", showType: 1)
                  ]);
                  break;
                case 2:
                  _controller.updateMarkers([
                    AddressInfo(GeoPoint(22.618959, 114.038225), "Pos1", index: 1, indexName: "1", showType: 2),
                    // 114.109808,22.568798 麦德龙
                    AddressInfo(GeoPoint(22.568798, 114.109808), "Pos2", index: 2, indexName: "2", showType: 2),
                    // 114.087063,22.548665 华新
                    AddressInfo(GeoPoint(22.525982, 113.93569), "Pos4", index: 4, indexName: "4", showType: 2),
                  ]);
                  break;
                case 3:
                  _controller.updateMarkers([
                    AddressInfo(GeoPoint(22.618959, 114.038225), "Pos1", index: 1, indexName: "1", showType: 3),
                    // 114.109808,22.568798 麦德龙
                    AddressInfo(GeoPoint(22.568798, 114.109808), "Pos2", index: 2, indexName: "2", showType: 3),
                    // 114.060541,22.529242
                    AddressInfo(GeoPoint(22.529242, 114.060541), "Pos3", index: 3, indexName: "3", showType: 3),
                  ]);
                  break;
              }
            },
            param: AmapParam(
              initialCenterPoint: [22.630019, 114.068159],
              enableMyMarker: true,
              mapType: AmapParam.addressDescriptionMap,
              merchantAddressList: [
                // 114.038225,22.618959
                AddressInfo(GeoPoint(22.618959, 114.038225), "Pos1", index: 1, indexName: "1", showType: 0),
                // 114.109808,22.568798 麦德龙
                AddressInfo(GeoPoint(22.568798, 114.109808), "Pos2", index: 2, indexName: "2", showType: 0),
                // 114.060541,22.529242
                AddressInfo(GeoPoint(22.529242, 114.060541), "Pos3", index: 3, indexName: "3", showType: 0),
                // 114.087063,22.548665 华新
                AddressInfo(GeoPoint(22.525982, 113.93569), "Pos4", index: 4, indexName: "4", showType: 0),
              ],
            ),
          ),
          Positioned(
            bottom: 80,
            right: 0,
            child: RaisedButton(
              child: Text("放大"),
              onPressed: () {
                _controller.zoomIn();
              },
            ),
          ),
          Positioned(
            bottom: 40,
            right: 0,
            child: RaisedButton(
              child: Text("缩小"),
              onPressed: () {
                _controller.zoomOut();
              },
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: RaisedButton(
              child: Text("定位"),
              onPressed: () {
                _controller.locateMyPosition();
              },
            ),
          )
        ],
      ),
    );
  }
}