import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'amap_param.dart';

class AmapView extends StatefulWidget {

  final AMapController controller;
  final AmapParam param;
  final Function(int, String) onMarkerClick;

  AmapView({this.controller, this.param, this.onMarkerClick});

  @override
  _AmapViewState createState() => _AmapViewState(this.controller);
}

class _AmapViewState extends State<AmapView> {
  static final String viewType = "xh.zero/amap_view";

  final AMapController _controller;
  MethodChannel _channel;

  _AmapViewState(this._controller) {
    _controller._setState(this);
    _channel = MethodChannel("xh.zero/amap_view_method");
    _channel.setMethodCallHandler((call) {
      switch (call.method) {
        case "clickMarker":
          final index = call.arguments["index"] as int;
          final distance = call.arguments["distance"] as String;
          widget.onMarkerClick(index, distance);
          break;
      }
      return Future.value(null);
    });
  }

  locateMyLocation() {
    _channel.invokeMethod("locateMyLocation");
  }

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

  onMarkerClick(Function(int) callback) => _state.onMarkerClick(callback);

}