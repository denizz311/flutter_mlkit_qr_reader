import 'dart:async';
import 'dart:typed_data';

import 'package:camera2/camera2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mlkit_qr_reader/flutter_mlkit_qr_reader.dart';
import 'package:image/image.dart' as image;
import 'package:permission_handler/permission_handler.dart';

class QrReaderScreen extends StatefulWidget {
  const QrReaderScreen({Key key}) : super(key: key);

  @override
  _QrReaderScreenState createState() => _QrReaderScreenState();
}

class _QrReaderScreenState extends State<QrReaderScreen> {
  CameraPreviewController _ctrl;

  var _hasPermission = false;

  var _fps = 0.0;
  var _requestImageDurationMs = 0.0;
  var _processImageDurationMs = 0.0;
  final _previewImage = image.Image(224, 224);

  var _detectedObjects = [];

  final _convertedAnalysisImageBytes = StreamController<Uint8List>();

  static const _displayImagePreview = false;

  static const _bitmapWidth = 224.0;
  static const _bitmapHeight = 224.0;

  static const _centerCropAspectRatio = 1.0;
  static const _centerCropWidthPercent = 0.9;

  final _detector = FlutterMlkitQrReader(
    bitmapSize: const Size(_bitmapWidth, _bitmapHeight),
  );

  Future<void> _runDetection() async {
    final permissionStatus = await Permission.camera.request();
    if (permissionStatus == PermissionStatus.granted) {
      _hasPermission = true;
      if (mounted) {
        setState(() {});
      }
    }

    final stopwatch = Stopwatch();
    var totalPasses = 0;

    final reqImageStopwatch = Stopwatch();
    var totalRequests = 0;

    final processImageStopwatch = Stopwatch();
    var totalProcesses = 0;

    while (mounted) {
      if (_ctrl == null) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
        continue;
      }
      stopwatch.start();

      reqImageStopwatch.start();
      final imageBytes = await _ctrl.requestImageForAnalysis();
      reqImageStopwatch.stop();
      totalRequests++;
      _requestImageDurationMs =
          reqImageStopwatch.elapsedMilliseconds / totalRequests;

      if (imageBytes != null) {
        if (_displayImagePreview) {
          _writePreviewAnalysisImage(imageBytes);
        }
        try {
          processImageStopwatch.start();
          final results = await _detector.process(imageBytes);
          processImageStopwatch.stop();
          _detectedObjects = results;
          totalProcesses++;
          _processImageDurationMs =
              processImageStopwatch.elapsedMilliseconds / totalProcesses;
        } catch (e) {
          debugPrint(e.toString());
        }
      } else {
        totalPasses = 0;
        stopwatch.stop();
        stopwatch.reset();
      }

      stopwatch.stop();
      totalPasses += 1;
      _fps = totalPasses / stopwatch.elapsedMilliseconds * 1000;

      if (mounted) {
        setState(() {});
      }
    }
    stopwatch.stop();
  }

  @override
  void initState() {
    super.initState();
    _detector.init();
    _runDetection();
  }

  @override
  void dispose() {
    super.dispose();
    _detector.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Qr Analysis'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 24,
            alignment: Alignment.topCenter,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Column(
                  children: [
                    Text(
                      'FPS: ${_fps.toStringAsFixed(1)}, '
                      'REQUEST: ${_requestImageDurationMs.toStringAsFixed(1)}, '
                      'PROCESS: ${_processImageDurationMs.toStringAsFixed(1)}',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: _hasPermission ? _buildPreview() : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildPreview() {
    return Stack(
      alignment: Alignment.center,
      children: [
        AspectRatio(
          aspectRatio: 1,
          child: Camera2Preview(
            analysisOptions: const Camera2AnalysisOptions(
              imageSize: const Size(_bitmapWidth, _bitmapHeight),
              colorOrder: ColorOrder.rgb,
              normalization: Normalization.ubyte,
              centerCropWidthPercent: _centerCropWidthPercent,
              centerCropAspectRatio: _centerCropAspectRatio,
            ),
            onPlatformViewCreated: (ctrl) => _ctrl = ctrl,
          ),
        ),
        if (_displayImagePreview) ...[
          Opacity(
            opacity: 0.25,
            child: StreamBuilder<Uint8List>(
              stream: _convertedAnalysisImageBytes.stream,
              builder: (context, snapshot) => snapshot.hasData
                  ? Image.memory(
                      snapshot.data,
                      gaplessPlayback: true,
                      isAntiAlias: true,
                      fit: BoxFit.contain,
                    )
                  : Container(),
            ),
          ),
        ],
        SizedBox(
          width: MediaQuery.of(context).size.width * _centerCropWidthPercent,
          child: AspectRatio(
            aspectRatio: _centerCropAspectRatio,
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.red),
              ),
            ),
          ),
        ),
        _buildObjectBoxes(),
      ],
    );
  }

  Widget _buildObjectBoxes() {
    final previewWidth =
        MediaQuery.of(context).size.width * _centerCropWidthPercent;
    final widthRatio = _bitmapWidth / previewWidth;
    final previewHeight = previewWidth / _centerCropAspectRatio;
    final heightRatio = _bitmapHeight / previewHeight;
    return SizedBox(
      width: previewWidth,
      child: AspectRatio(
        aspectRatio: _centerCropAspectRatio,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Text(_detectedObjects.toString()),
          ],
        ),
      ),
    );
  }

  void _writePreviewAnalysisImage(Uint8List imageBytes) {
    final pixelsAmount = imageBytes.lengthInBytes ~/ 3;

    var i = 0;
    var j = 0;
    while (j < pixelsAmount) {
      _previewImage.setPixel(
        j % _previewImage.width,
        j ~/ _previewImage.height,
        Color.fromARGB(
          255,
          imageBytes[i],
          imageBytes[i + 1],
          imageBytes[i + 2],
        ).value,
      );
      i += 3;
      j++;
    }
    if (!_convertedAnalysisImageBytes.isClosed) {
      _convertedAnalysisImageBytes.add(
        Uint8List.fromList(image.encodePng(_previewImage)),
      );
    }
  }
}
