import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class AmapInitializer {
  static final _channel = MethodChannel("com.pgy/amap_initial");

  static setApiKey({
    @required String androidKey,
    @required String iosKey,
  }) async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      await _channel.invokeMethod("initial", { "apiKey": androidKey });
    } else {
      await _channel.invokeMethod("initial", { "apiKey": iosKey });
    }
  }
}