import 'dart:async';

import 'package:flutter/services.dart';

const _channel = MethodChannel('flutter_mlkit_qr_reader');

class FlutterMlkitQrReader {
  static Future<String> get platformVersion async {
    final String version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }
}
