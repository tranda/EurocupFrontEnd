import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Utility for generating and verifying signed QR codes for athletes.
///
/// Format: EVT.<base64_payload>.<signature>
/// Payload contains athlete id, club id, and timestamp.
/// Signature is HMAC-SHA256 truncated to 8 chars.
class QrCodeUtil {
  static const String _prefix = 'EVT';
  static const String _secretKey = 'EvtsPlatform2026!SecretKey';

  /// Generate a signed QR code string for an athlete
  static String generate({required int athleteId, required int clubId}) {
    final payload = {
      'id': athleteId,
      'cid': clubId,
      't': DateTime.now().millisecondsSinceEpoch ~/ 1000,
    };

    final payloadBase64 = base64Url.encode(utf8.encode(jsonEncode(payload)));
    final signature = _sign(payloadBase64);

    return '$_prefix.$payloadBase64.$signature';
  }

  /// Decode and verify a QR code string. Returns athlete ID if valid, null if invalid.
  static int? verify(String qrCode) {
    try {
      final parts = qrCode.split('.');
      if (parts.length != 3 || parts[0] != _prefix) return null;

      final payloadBase64 = parts[1];
      final signature = parts[2];

      // Verify signature
      if (_sign(payloadBase64) != signature) return null;

      final payload = jsonDecode(utf8.decode(base64Url.decode(payloadBase64)));
      return payload['id'] as int?;
    } catch (e) {
      return null;
    }
  }

  /// Create HMAC-SHA256 signature, truncated to 8 chars
  static String _sign(String data) {
    final key = utf8.encode(_secretKey);
    final bytes = utf8.encode(data);
    final hmacSha256 = Hmac(sha256, key);
    final digest = hmacSha256.convert(bytes);
    return digest.toString().substring(0, 8);
  }
}
