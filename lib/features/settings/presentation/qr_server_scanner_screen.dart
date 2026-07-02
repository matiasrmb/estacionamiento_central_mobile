import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QrServerScannerScreen extends StatefulWidget {
  const QrServerScannerScreen({super.key});

  @override
  State<QrServerScannerScreen> createState() => _QrServerScannerScreenState();
}

class _QrServerScannerScreenState extends State<QrServerScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _handled = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleDetect(BarcodeCapture capture) {
    if (_handled) return;
    String? value;
    for (final barcode in capture.barcodes) {
      final rawValue = barcode.rawValue;
      if (rawValue != null && rawValue.trim().isNotEmpty) {
        value = rawValue;
        break;
      }
    }
    if (value == null || value.trim().isEmpty) return;

    _handled = true;
    _controller.stop();
    Navigator.of(context).pop(value.trim());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Escanear servidor')),
      body: Stack(
        children: [
          MobileScanner(controller: _controller, onDetect: _handleDetect),
          const Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    'Escanea el QR o la guía generada por el instalador en la máquina donde está la API.',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
