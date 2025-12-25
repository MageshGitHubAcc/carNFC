import 'package:flutter/material.dart';
import 'package:nfc_manager/nfc_manager.dart';

class WriteNfcScreen extends StatelessWidget {
  const WriteNfcScreen({super.key});

  void writeTag() async {
    bool isAvailable = await NfcManager.instance.isAvailable();
    if (!isAvailable) {
      debugPrint('NFC not available');
      return;
    }

    NfcManager.instance.startSession(
      onDiscovered: (NfcTag tag) async {
        try {
          final ndef = Ndef.from(tag);

          if (ndef == null || !ndef.isWritable) {
            debugPrint('Tag is not NDEF writable');
            NfcManager.instance.stopSession(errorMessage: 'Not writable');
            return;
          }

          final message = NdefMessage([
            NdefRecord.createText('Parking Slot A12'),
          ]);

          await ndef.write(message);
          NfcManager.instance.stopSession();
          debugPrint('NFC Write Successful');
        } catch (e) {
          NfcManager.instance.stopSession(errorMessage: e.toString());
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('NFC Writer')),
      body: Column(
        children: [
          const Text('NFC Writer'),
          ElevatedButton(
            onPressed: writeTag,
            child: const Text('Write NFC Tag'),
          ),

          const Text('NFC Reader'),
          ElevatedButton(onPressed: readTag, child: const Text('Read NFC Tag')),
        ],
      ),
    );
  }

  Future<void> readTag() async {
    bool isAvailable = await NfcManager.instance.isAvailable();
    if (!isAvailable) {
      debugPrint('NFC not available');
      return;
    }
    NfcManager.instance.startSession(
      onDiscovered: (NfcTag tag) async {
        try {
          final ndef = Ndef.from(tag);
          if (ndef == null || !ndef.isWritable) {
            debugPrint('Tag is not NDEF writable');
            NfcManager.instance.stopSession(errorMessage: 'Not writable');
            return;
          }

          final message = await ndef.read();
          debugPrint('NFC Read Successful $message');
          NfcManager.instance.stopSession();
        } catch (e) {
          debugPrint('NFC Read Failed $e');
          NfcManager.instance.stopSession(errorMessage: e.toString());
        }
      },
    );
  }
}
