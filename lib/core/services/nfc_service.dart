import 'dart:async';
import 'dart:convert';
import 'package:nfc_manager/nfc_manager.dart';

class NFCService {
  bool _sessionActive = false;

  /* ---------------------------------------------------------
   * Check NFC availability
   * --------------------------------------------------------- */
  Future<bool> isNFCAvailable() async {
    return await NfcManager.instance.isAvailable();
  }

  /* ---------------------------------------------------------
   * READ NFC TAG (JSON MIME RECORD)
   * --------------------------------------------------------- */
  Future<Map<String, dynamic>?> readNFCTag() async {
    if (_sessionActive) return null;
    _sessionActive = true;

    final completer = Completer<Map<String, dynamic>?>();

    try {
      await NfcManager.instance.startSession(
        onDiscovered: (NfcTag tag) async {
          try {
            final ndef = Ndef.from(tag);
            if (ndef == null) {
              throw Exception('Tag is not NDEF formatted');
            }

            final message = ndef.cachedMessage;
            if (message == null || message.records.isEmpty) {
              throw Exception('NFC tag is empty');
            }

            final record = message.records.first;

            if (record.typeNameFormat != NdefTypeNameFormat.media) {
              throw Exception('Unsupported NFC record type');
            }

            final jsonString = utf8.decode(record.payload);
            final data = jsonDecode(jsonString) as Map<String, dynamic>;

            await NfcManager.instance.stopSession();
            completer.complete(data);
          } catch (e) {
            await NfcManager.instance.stopSession(errorMessage: e.toString());
            completer.complete(null);
          } finally {
            _sessionActive = false;
          }
        },
      );
    } catch (e) {
      _sessionActive = false;
      rethrow;
    }

    return completer.future;
  }

  /* ---------------------------------------------------------
   * WRITE NFC TAG (JSON MIME RECORD)
   * --------------------------------------------------------- */
  Future<bool> writeNFCTag(Map<String, dynamic> data) async {
    if (_sessionActive) return false;
    _sessionActive = true;

    final completer = Completer<bool>();

    try {
      await NfcManager.instance.startSession(
        onDiscovered: (NfcTag tag) async {
          try {
            final ndef = Ndef.from(tag);
            if (ndef == null || !ndef.isWritable) {
              throw Exception('NFC tag is not writable');
            }

            final payload = utf8.encode(jsonEncode(data));

            final message = NdefMessage([
              NdefRecord.createMime('application/json', payload),
            ]);

            await ndef.write(message);
            await NfcManager.instance.stopSession();
            completer.complete(true);
          } catch (e) {
            await NfcManager.instance.stopSession(errorMessage: e.toString());
            completer.complete(false);
          } finally {
            _sessionActive = false;
          }
        },
      );
    } catch (e) {
      _sessionActive = false;
      rethrow;
    }

    return completer.future;
  }

  /* ---------------------------------------------------------
   * CLEAR NFC TAG
   * --------------------------------------------------------- */
  Future<bool> clearNFCTag() async {
    if (_sessionActive) return false;
    _sessionActive = true;

    final completer = Completer<bool>();

    try {
      await NfcManager.instance.startSession(
        onDiscovered: (NfcTag tag) async {
          try {
            final ndef = Ndef.from(tag);
            if (ndef == null || !ndef.isWritable) {
              throw Exception('NFC tag is not writable');
            }

            await ndef.write(const NdefMessage([]));
            await NfcManager.instance.stopSession();
            completer.complete(true);
          } catch (e) {
            await NfcManager.instance.stopSession(errorMessage: e.toString());
            completer.complete(false);
          } finally {
            _sessionActive = false;
          }
        },
      );
    } catch (e) {
      _sessionActive = false;
      rethrow;
    }

    return completer.future;
  }

  /* ---------------------------------------------------------
   * STOP SESSION (SAFE)
   * --------------------------------------------------------- */
  void stopSession() {
    if (_sessionActive) {
      NfcManager.instance.stopSession();
      _sessionActive = false;
    }
  }
}
