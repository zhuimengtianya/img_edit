import 'dart:async';

import 'package:flutter/services.dart';

class FlutterEditImgSdk {
  static const MethodChannel _channel =
      const MethodChannel('flutter_edit_img_sdk');

  static Future<String> get platformVersion async {
    final String version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }
}
