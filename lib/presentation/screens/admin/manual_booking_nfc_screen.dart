import 'package:flutter/material.dart';
import 'package:flutter_app/core/services/nfc_service.dart';

class ManualBookingNfcArgs {
  final Map<String, dynamic> nfcData;

  const ManualBookingNfcArgs({required this.nfcData});
}

class ManualBookingNfcScreen extends StatefulWidget {
  static const routeName = '/admin/manual-booking/nfc-write';

  final Map<String, dynamic> nfcData;

  const ManualBookingNfcScreen({super.key, required this.nfcData});

  @override
  State<ManualBookingNfcScreen> createState() => _ManualBookingNfcScreenState();
}

class _ManualBookingNfcScreenState extends State<ManualBookingNfcScreen> {
  final NFCService _nfcService = NFCService();

  bool _isWriting = false;
  bool? _writeSuccess;
  String? _errorMessage;

  @override
  void dispose() {
    _nfcService.stopSession();
    super.dispose();
  }

  /* -----------------------------------------------------------
   * START WRITE SESSION
   * ----------------------------------------------------------- */
  Future<void> _beginWriteSession() async {
    if (_isWriting) return;

    final isAvailable = await _nfcService.isNFCAvailable();
    if (!isAvailable) {
      setState(() {
        _writeSuccess = false;
        _errorMessage = 'NFC is not available on this device';
      });
      return;
    }

    setState(() {
      _isWriting = true;
      _writeSuccess = null;
      _errorMessage = null;
    });

    try {
      final success = await _nfcService.writeNFCTag(widget.nfcData);

      if (!mounted) return;

      setState(() {
        _isWriting = false;
        _writeSuccess = success;
        _errorMessage = success
            ? null
            : 'Unable to write NFC tag. Please retry.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isWriting = false;
        _writeSuccess = false;
        _errorMessage = e.toString();
      });
    }
  }

  void _cancelAndExit([bool result = false]) {
    _nfcService.stopSession();
    if (mounted) Navigator.of(context).pop(result);
  }

  /* -----------------------------------------------------------
   * STATUS UI
   * ----------------------------------------------------------- */
  Widget _buildStatusContent() {
    if (_writeSuccess == true) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.check_circle, color: Colors.green, size: 72),
          SizedBox(height: 16),
          Text(
            'NFC tag written successfully!',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          Text('Tap Done to finish and return.', textAlign: TextAlign.center),
        ],
      );
    }

    if (_writeSuccess == false) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: Colors.orange, size: 72),
          const SizedBox(height: 16),
          const Text(
            'Failed to write NFC tag',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13),
            ),
          ],
        ],
      );
    }

    if (_isWriting) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          SizedBox(
            height: 64,
            width: 64,
            child: CircularProgressIndicator(strokeWidth: 4),
          ),
          SizedBox(height: 16),
          Text('Hold the NFC tag near the device', textAlign: TextAlign.center),
        ],
      );
    }

    return const Text(
      'Tap "Write to Tag" and hold the NFC tag near the device.',
      textAlign: TextAlign.center,
    );
  }

  /* -----------------------------------------------------------
   * ACTION BUTTONS
   * ----------------------------------------------------------- */
  List<Widget> _buildActions() {
    if (_writeSuccess == true) {
      return [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _cancelAndExit(true),
            icon: const Icon(Icons.check),
            label: const Text('Done'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ];
    }

    if (_writeSuccess == false) {
      return [
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: _isWriting ? null : () => _cancelAndExit(false),
            child: const Text('Cancel'),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isWriting ? null : _beginWriteSession,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry Write'),
          ),
        ),
      ];
    }

    return [
      SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: _isWriting ? null : () => _cancelAndExit(false),
          child: const Text('Cancel'),
        ),
      ),
      const SizedBox(height: 12),
      SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _isWriting ? null : _beginWriteSession,
          icon: const Icon(Icons.nfc),
          label: const Text('Write to Tag'),
        ),
      ),
    ];
  }

  /* -----------------------------------------------------------
   * UI
   * ----------------------------------------------------------- */
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Write NFC Tag'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => _cancelAndExit(false),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Manual Check-in NFC',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Booking ID: ${widget.nfcData['bookingId']}',
                style: const TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: _buildStatusContent(),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ..._buildActions(),
            ],
          ),
        ),
      ),
    );
  }
}
