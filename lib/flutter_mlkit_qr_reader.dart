import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class FlutterMlkitQrReader {
  FlutterMlkitQrReader({
    @required this.bitmapSize,
  }) : assert(bitmapSize != null);

  /// Usually is 192x192
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

  Future<List<String>> process(Uint8List rgbBytes) async {
    try {
      final id = await _idCompleter.future;
      final results = await _channel.invokeMethod<List>('processImage', {
        'detectorId': id,
        'rgbBytes': rgbBytes,
      });

      if (results?.isNotEmpty == true) {
        debugPrint('results.isNotEmpty');
      }

      return results.map((e) => e.toString()).toList();
    } catch (e) {
      return [e.toString()];
    }
  }

  Future<void> dispose() async {
    final id = await _idCompleter.future;
    await _channel.invokeMethod('disposeDetector', {
      'id': id,
    });
  }
}
