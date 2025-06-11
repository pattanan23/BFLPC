import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class BarcodeScannerPage extends StatefulWidget {
  const BarcodeScannerPage({super.key});

  @override
  State<BarcodeScannerPage> createState() => _BarcodeScannerPageState();
}

class _BarcodeScannerPageState extends State<BarcodeScannerPage> {
  final MobileScannerController controller = MobileScannerController();
  double zoom = 0.0;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  bool _isScanned = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan Barcode')),
      body: Stack(
      children: [
        MobileScanner(
          controller: controller,
          onDetect: (BarcodeCapture capture) async {
            if (_isScanned) return;

            final List<Barcode> barcodes = capture.barcodes;
            if (barcodes.isNotEmpty) {
              final String? code = barcodes.first.rawValue;
              if (code != null) {
                _isScanned = true;
                await controller.stop(); // Stop the camera first.
                await Future.delayed(const Duration(milliseconds: 300)); // Slight delay
                if (mounted) {
                  Navigator.pop(context, code);
                }
              }
            }
          },
        ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 32,
            child: Column(        
              children: [
                Slider(
                  value: zoom,
                  min: 0.0,
                  max: 1.0,
                  onChanged: (value) {
                    setState(() {
                      zoom = value;
                    });
                    controller.setZoomScale(value);
                  },
                ),
                Text('Zoom: ${(zoom * 100).toInt()}%'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
