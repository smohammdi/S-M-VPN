import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:sm_vpn/services/v2ray_service.dart';
import 'package:sm_vpn/theme/app_theme.dart';

/// QR code scanner: reads a config share-link from the camera or from a
/// gallery image, then adds the parsed config to the saved server list.
class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();
  final ImagePicker _imagePicker = ImagePicker();
  bool _isProcessing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _processScannedValue(String? rawValue) async {
    if (!mounted || _isProcessing) return;

    if (rawValue == null || rawValue.trim().isEmpty) {
      _showSnackBar('Unable to read QR code', isError: true);
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final service = Provider.of<V2RayService>(context, listen: false);
      final config = await service.parseConfigFromClipboard(rawValue.trim());

      if (!mounted) return;

      if (config != null) {
        _showSnackBar('Configuration added successfully');
        Navigator.of(context).pop(config);
      } else {
        _showSnackBar('Invalid configuration', isError: true);
      }
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Invalid configuration', isError: true);
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final xFile = await _imagePicker.pickImage(source: ImageSource.gallery);
      if (xFile == null) return;

      // Pause the camera feed while analyzing the picked image.
      await _controller.stop();
      final capture = await _controller.analyzeImage(xFile.path);

      if (!mounted) return;

      if (capture == null || capture.barcodes.isEmpty) {
        _showSnackBar('No QR code found in image', isError: true);
        await _controller.start();
        return;
      }

      await _processScannedValue(capture.barcodes.first.rawValue);
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Failed to read image', isError: true);
      try {
        await _controller.start();
      } catch (_) {}
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // The host app is a FluentApp: provide the Material helpers the scanner
    // UI relies on (text direction + scaffold messenger).
    return Directionality(
      textDirection: TextDirection.ltr,
      child: ScaffoldMessenger(
        child: Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            title: const Text('Scan QR Code'),
            backgroundColor: AppTheme.primary,
            foregroundColor: Colors.white,
          ),
          body: Stack(
            children: [
              MobileScanner(
                controller: _controller,
                onDetect: (capture) {
                  if (capture.barcodes.isNotEmpty) {
                    _processScannedValue(capture.barcodes.first.rawValue);
                  }
                },
              ),
              _buildScanOverlay(context),
              if (_isProcessing)
                Container(
                  color: Colors.black54,
                  child: const Center(
                    child: CircularProgressIndicator(color: AppTheme.primary),
                  ),
                ),
            ],
          ),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerDocked,
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _pickFromGallery,
            backgroundColor: AppTheme.primary,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.image),
            label: const Text('Pick from Gallery'),
          ),
        ),
      ),
    );
  }

  /// Semi-transparent purple overlay with a centered 250x250 transparent
  /// scan window outlined in white. Uses [BlendMode.srcOut], which keeps the
  /// overlay color only where the child is transparent, so the opaque center
  /// box becomes the see-through scan window.
  Widget _buildScanOverlay(BuildContext context) {
    const overlayColor = Color(0x996366F1);

    return Stack(
      children: [
        ColorFiltered(
          colorFilter: const ColorFilter.mode(
            overlayColor,
            BlendMode.srcOut,
          ),
          child: Stack(
            children: [
              Center(
                child: Container(
                  height: 250,
                  width: 250,
                  // Any opaque color: this region is punched out of the
                  // overlay so the camera feed shows through.
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),
        Center(
          child: Container(
            height: 250,
            width: 250,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white, width: 3),
            ),
          ),
        ),
      ],
    );
  }
}
