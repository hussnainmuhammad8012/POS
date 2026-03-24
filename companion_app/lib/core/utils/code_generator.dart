import 'dart:math' as math;

/// Centralized CodeGenerator for the Companion App. 
/// Synchronized with the Desktop POS system to ensure unified internal inventory data formats.
class CodeGenerator {
  /// Generates a 12-digit random numeric barcode.
  static String generateInternalBarcode() {
    final random = math.Random();
    String code = '';
    for (int i = 0; i < 12; i++) {
      code += random.nextInt(10).toString();
    }
    return code;
  }

  /// Generates an 8-character random alphanumeric QR code string.
  static String generateInternalQrCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = math.Random();
    String code = '';
    for (int i = 0; i < 8; i++) {
      code += chars[random.nextInt(chars.length)];
    }
    return code;
  }
}
