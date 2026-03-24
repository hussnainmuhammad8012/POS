import 'dart:math' as math;

class CodeGenerator {
  /// Generates a 12-digit random numeric barcode.
  /// This format is chosen for its compatibility with Code 128 symbology 
  /// and its compact representation on small labels.
  static String generateInternalBarcode() {
    final random = math.Random();
    String code = '';
    for (int i = 0; i < 12; i++) {
      code += random.nextInt(10).toString();
    }
    return code;
  }

  /// Generates an 8-character random alphanumeric QR code string.
  /// Uses uppercase letters and numbers for high scannability and unique identification.
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
