import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'amap_param.dart';

class AmapView extends StatefulWidget {

  final AMapController controller;
  final AmapParam param;
  final Function(int, String) onMarkerClick;
  final Function(int) onMapZoom;
  final Function(double, double) onLocate;

  AmapView({this.controller, this.param, this.onMarkerClick, this.onMapZoom, this.onLocate});

  @override
  _AmapViewState createState() => _AmapViewState(this.controller);
}

class _AmapViewState extends State<AmapView> {
  static final String viewType = "xh.zero/amap_view";

  final AMapController _controller;
  MethodChannel _channel;
  // EventChannel _eventChannel;
  // Stream<int> _zoomStream;

  _AmapViewState(this._controller) {
    _controller._setState(this);
    _channel = MethodChannel("xh.zero/amap_view_method");
    // _eventChannel = EventChannel("xh.zero/amap_view_event");
    _channel.setMethodCallHandler((call) {
      switch (call.method) {
        case "clickMarker":
          final index = call.arguments["index"] as int;
          final distance = call.arguments["distance"] as String;
          widget.onMarkerClick?.call(index, distance);
          break;
        case "onMapZoom":
          final zoomLevel = call.arguments["zoomLevel"] as int;
          widget.onMapZoom?.call(zoomLevel);
          break;
        case "onLocate":
          final lat = call.arguments["lat"] as double;
          final lng = call.arguments["lng"] as double;
          widget.onLocate?.call(lat, lng);
          break;
      }
      return Future.value(null);
    });
  }

  locateMyLocation() {
    _channel.invokeMethod("locateMyLocation");
  }

  zoomIn() {
    _channel.invokeMethod("zoomIn");
  }

  zoomOut() {
    _channel.invokeMethod("zoomOut");
  }

  updateMarkers(List<AddressInfo> markers) {
    final jsonData = json.encode(MarkerParam((markers)));
    _channel.invokeMethod("updateMarkers", jsonData);
  }

  // Stream<int> onMapZoom() {
  //   _zoomStream = _eventChannel.receiveBroadcastStream().map((dynamic data) => data as int);
  //   return _zoomStream;
  // }

  onMarkerClick(Function(int) callback) {

  }

  @override
  Widget build(BuildContext context) {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return AndroidView(
        viewType: viewType,
        onPlatformViewCreated: _onPlatformViewCreated,
        creationParams: json.encode(widget.param),
        creationParamsCodec: StandardMessageCodec(),
      );
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      return UiKitView(
        viewType: viewType,
        onPlatformViewCreated: _onPlatformViewCreated,
        creationParams: json.encode(widget.param),
        creationParamsCodec: StandardMessageCodec(),
      );
    }

    return Text("Not support platform");
  }

  void _onPlatformViewCreated(int id) {

  }
}

class AMapController {
  _AmapViewState _state;

  _setState(_AmapViewState state) {
    _state = state;
  }

  locateMyPosition() {
    _state.locateMyLocation();
  }

  // 放大
  zoomIn() {
    _state.zoomIn();
  }

  // 缩小
  zoomOut() {
    _state.zoomOut();
  }

  updateMarkers(List<AddressInfo> markers) {
    _state.updateMarkers(markers);
  }

  // Stream<int> onMapZoom() {
  //   return _state.onMapZoom();
  // }

  onMarkerClick(Function(int) callback) => _state.onMarkerClick(callback);

}