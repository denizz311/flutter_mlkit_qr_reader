import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class FlutterMlkitQrReader {
  FlutterMlkitQrReader({
    @required this.bitmapSize,
  });

  final Size bitmapSize;

  static const MethodChannel _channel =
      const MethodChannel('flutter_mlkit_qr_reader');

  static Future<String> get platformVersion async {
    final String version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }

  final _idCompleter = Completer<int>();

  Future<void> init() async {
    try {
      final id = await _channel.invokeMethod('prepareDetector', {
        'bitmapWidth': bitmapSize.width.toInt(),
        'bitmapHeight': bitmapSize.height.toInt(),
      });
      _idCompleter.complete(id);
    } catch (e, stackTrace) {
      _idCompleter.completeError(e, stackTrace);
      rethrow;
    }
  }

  Future<String> process(Uint8List rgbBytes) async {
    final id = await _idCompleter.future;
    final results = await _channel.invokeMethod<String>('processImage', {
      'detectorId': id,
      'rgbBytes': rgbBytes,
    });

    if (results.isNotEmpty) {
      debugPrint('results.isNotEmpty');
    }

    return results;
  }

  Future<void> dispose() async {
    final id = await _idCompleter.future;
    await _channel.invokeMethod('disposeDetector', {
      'id': id,
    });
  }
}
