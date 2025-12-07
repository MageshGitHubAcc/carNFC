import 'package:nfc_manager/nfc_manager.dart';
import 'dart:convert';

class NFCService {
  Future<bool> isNFCAvailable() async {
    return await NfcManager.instance.isAvailable();
  }

  Future<Map<String, dynamic>?> readNFCTag() async {
    try {
      Map<String, dynamic>? result;

      await NfcManager.instance.startSession(
        onDiscovered: (NfcTag tag) async {
          try {
            final ndef = Ndef.from(tag);
            if (ndef == null || !ndef.isWritable) {
              result = null;
              await NfcManager.instance.stopSession(
                errorMessage: 'Tag is not NDEF writable',
              );
              return;
            }

            final cachedMessage = ndef.cachedMessage;
            if (cachedMessage != null && cachedMessage.records.isNotEmpty) {
              final record = cachedMessage.records.first;
              final payload = String.fromCharCodes(record.payload);

              // Parse JSON data from NFC tag
              result = jsonDecode(payload) as Map<String, dynamic>;
              await NfcManager.instance.stopSession();
            }
          } catch (e) {
            result = null;
            await NfcManager.instance.stopSession(
              errorMessage: 'Error reading tag: $e',
            );
          }
        },
      );

      return result;
    } catch (e) {
      throw Exception('NFC Read Error: $e');
    }
  }

  Future<bool> writeNFCTag(Map<String, dynamic> data) async {
    try {
      bool success = false;

      await NfcManager.instance.startSession(
        onDiscovered: (NfcTag tag) async {
          try {
            final ndef = Ndef.from(tag);
            if (ndef == null || !ndef.isWritable) {
              await NfcManager.instance.stopSession(
                errorMessage: 'Tag is not writable',
              );
              return;
            }

            final jsonString = jsonEncode(data);
            final ndefMessage = NdefMessage([
              NdefRecord.createText(jsonString),
            ]);

            await ndef.write(ndefMessage);
            success = true;
            await NfcManager.instance.stopSession();
          } catch (e) {
            await NfcManager.instance.stopSession(
              errorMessage: 'Write failed: $e',
            );
          }
        },
      );

      return success;
    } catch (e) {
      throw Exception('NFC Write Error: $e');
    }
  }

  void stopSession() {
    NfcManager.instance.stopSession();
  }

  Future<bool> clearNFCTag() async {
    try {
      bool success = false;

      await NfcManager.instance.startSession(
        onDiscovered: (NfcTag tag) async {
          try {
            final ndef = Ndef.from(tag);
            if (ndef == null || !ndef.isWritable) {
              await NfcManager.instance.stopSession(
                errorMessage: 'Tag is not writable',
              );
              return;
            }

            // Write an empty NDEF message to clear the tag
            final ndefMessage = NdefMessage([]);
            await ndef.write(ndefMessage);
            success = true;
            await NfcManager.instance.stopSession();
          } catch (e) {
            await NfcManager.instance.stopSession(
              errorMessage: 'Clear failed: $e',
            );
          }
        },
      );

      return success;
    } catch (e) {
      throw Exception('NFC Clear Error: $e');
    }
  }
}
