import 'dart:async';
// Conditional imports for platform-specific packages.
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html; // Web import

import 'package:ads_schools/widgets/my_widgets.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart'; // Mobile import

// ===============================================================
//                Unified QR Code Scanner Widget
// ===============================================================

class CrossPlatformQrScanner extends StatefulWidget {
  const CrossPlatformQrScanner({super.key});
  @override
  State<CrossPlatformQrScanner> createState() => _CrossPlatformQrScannerState();
}

// ===============================================================
//           Abstract Interface for QR Code Scanning
// ===============================================================

abstract class QrScanner {
  Widget buildUi();
  void dispose();
  Future<String?> startScan();
}

// ===============================================================
//            Mobile Implementation for QR Code Scanning
// ===============================================================

class QrScannerMobile implements QrScanner {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  String? _scannedData;
  bool _isScanning = false;

  @override
  Widget buildUi() {
    return QRView(
      key: qrKey,
      onQRViewCreated: _onQRViewCreated,
    );
  }

  @override
  void dispose() {
    controller?.dispose();
  }

  @override
  Future<String?> startScan() async {
    if (_isScanning) {
      return _scannedData;
    }
    _isScanning = true;
    while (_scannedData == null && _isScanning) {
      await Future.delayed(const Duration(milliseconds: 50));
    }
    _isScanning = false;
    String? data = _scannedData;
    _scannedData = null;
    return data;
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) {
      if (_isScanning && _scannedData == null) {
        _scannedData = scanData.code;
      }
    });
  }
}

// ===============================================================
//            Web Implementation for QR Code Scanning
// ===============================================================

class QrScannerWeb implements QrScanner {
  late html.VideoElement _videoElement;
  late html.CanvasElement _canvasElement;
  late html.MediaStream _mediaStream;
  late html.MediaStreamTrack _mediaStreamTrack;
  Timer? _timer;
  String? _scannedData;
  bool _isScanning = false;

  @override
  Widget buildUi() {
    return SizedBox(
      width: 300,
      height: 300,
      child: Stack(
        children: [
          HtmlElementView(viewType: 'videoElement'),
          HtmlElementView(viewType: 'canvasElement'),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _mediaStreamTrack.stop();
    _mediaStream.getVideoTracks().forEach((track) {
      track.stop();
    });
    _videoElement.remove();
    _canvasElement.remove();
  }

  @override
  Future<String?> startScan() async {
    if (_isScanning) {
      return _scannedData;
    }
    _isScanning = true;
    await _init();
    while (_scannedData == null && _isScanning) {
      await Future.delayed(const Duration(milliseconds: 50));
    }
    _isScanning = false;
    String? data = _scannedData;
    _scannedData = null;
    return data;
  }

  Future<void> _decode() async {
    try {
      _canvasElement.width = _videoElement.videoWidth;
      _canvasElement.height = _videoElement.videoHeight;

      final context = _canvasElement.context2D;
      context.drawImage(_videoElement, 0, 0);
/*
      final imageData = context.getImageData(0, 0, _canvasElement.width!, _canvasElement.height!);
      final code =  html.js_util.callMethod(html.window.jsObject, 'jsQR', [imageData.data,imageData.width, imageData.height]);

      if(code != null){
        _scannedData = code.text;
      }
      */
    } catch (e) {
      // print(e);
    }
  }

  Future<void> _init() async {
    try {
      _videoElement = html.VideoElement();
      _canvasElement = html.CanvasElement();
      html.MediaDevices? mediaDevices = html.window.navigator.mediaDevices;

      if (mediaDevices == null) {
        throw Exception("Media Devices is not available");
      }

      _mediaStream = await mediaDevices.getUserMedia({'video': true});
      _mediaStreamTrack = _mediaStream.getVideoTracks().first;
      _videoElement.srcObject = _mediaStream;
      _videoElement.setAttribute('playsinline', 'true');
      await _videoElement.play();
      _startScanLoop();
    } catch (e) {
      print("Failed to init camera in web");
    }
  }

  Future<void> _startScanLoop() async {
    _timer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (_scannedData != null || !_isScanning) {
        return;
      }
      _decode();
    });
  }
}

class _CrossPlatformQrScannerState extends State<CrossPlatformQrScanner> {
  late QrScanner _qrScanner;
  String? scannedData;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MyAppBar(isLoading: false),
      body: Column(
        children: [
          _qrScanner.buildUi(),
          const SizedBox(
            height: 10,
          ),
          ElevatedButton(
              onPressed: () async {
                scannedData = await _qrScanner.startScan();
                setState(() {});
              },
              child: const Text('Start Scan')),
          const SizedBox(
            height: 10,
          ),
          Text("Scanned Result: ${scannedData ?? "No Data"}"),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _qrScanner.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _qrScanner = kIsWeb ? QrScannerWeb() : QrScannerMobile();
  }
}
