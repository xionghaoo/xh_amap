import 'dart:async';

import 'package:flutter/services.dart';

typedef OnceLocationCallBack(
    double lat,
    double lng,
    String province,
    String district,
    String city,
    String address
);

class AmapLocationService {

  factory AmapLocationService() {
    if (_instance == null) {
      final methodChannel = MethodChannel("com.pgy/amap_location");
      final eventChannel = EventChannel("com.pgy/amap_location_stream");
      _instance = AmapLocationService._private(methodChannel, eventChannel);
    }
    return _instance;
  }

  static AmapLocationService _instance;
  OnceLocationCallBack _callback;

  AmapLocationService._private(this._methodChannel, this._eventChannel) {
    _methodChannel.setMethodCallHandler((call) {
      switch (call.method) {
        case "onOnceLocation":
          final lat = call.arguments["lat"] as double;
          final lng = call.arguments["lng"] as double;
          final province = call.arguments["province"] as String;
          final district = call.arguments["district"] as String;
          final city = call.arguments["city"] as String;
          final address = call.arguments["address"] as String;
          _callback?.call(lat, lng, province, district, city, address);
          break;
      }
      return Future.value(null);
    });
  }

  final MethodChannel _methodChannel;
  final EventChannel _eventChannel;
  Stream<Map<String, dynamic>> _locationStream;

  Future<void> start() async {
    return await _methodChannel.invokeMethod("startLocation");
  }
  
  locationOnce(OnceLocationCallBack callback) async {
    _callback = callback;
    _methodChannel.invokeMethod("locateOnce");
  }

  Stream<Map<String, dynamic>> startLocationStream() {
    if (_locationStream == null) {
      _locationStream = _eventChannel.receiveBroadcastStream().map((dynamic data) => {
        "address": data["address"] as String,
        "lat": data["lat"] as double,
        "lng": data["lng"] as double
      });
    }
    return _locationStream;
  }

  stop() async {
    return await _methodChannel.invokeMethod("stopLocation");
  }

}