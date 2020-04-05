import 'dart:async';

import 'package:flutter/services.dart';

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

  AmapLocationService._private(this._methodChannel, this._eventChannel);

  final MethodChannel _methodChannel;
  final EventChannel _eventChannel;
  Stream<Map<String, dynamic>> _locationStream;

//  static final _channel = MethodChannel("com.pgy/amap_location");
//  static StreamSubscription<dynamic> _locationSubscription;

  Future<void> start() async {
//    return await _channel.invokeMethod("startLocation");
    return await _methodChannel.invokeMethod("startLocation");
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

//  static stopLocationStream() async {
//    await _locationSubscription.cancel();
//    _locationSubscription = null;
//  }
}