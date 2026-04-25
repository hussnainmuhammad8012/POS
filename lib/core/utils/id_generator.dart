import 'dart:math';

/// Collision-proof ID generator.
///
/// Uses three layers of entropy to guarantee uniqueness even when called
/// thousands of times in the same microsecond (e.g. during bulk checkout loops):
///   1. Microsecond timestamp  — guards against cross-session collisions
///   2. Monotonic sequence counter — guarantees uniqueness within a single run,
///      even if the clock resolution is coarser than the call rate
///   3. Cryptographic-quality random hex — guards against multi-instance collisions
///
/// Format: [prefix]_[microseconds]_[seq]_[randomHex6]
/// Example: txn_1713346800123456_0042_a3f2c1
class IdGenerator {
  static final Random _random = Random.secure();
  static int _seq = 0; // monotonically increasing within the process lifetime

  /// Returns a unique ID. Thread-safe in Dart's single-threaded model.
  static String generate(String prefix) {
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    final seq = _seq++;
    final randomPart = _random.nextInt(0xFFFFFF).toRadixString(16).padLeft(6, '0');
    return '${prefix}_${timestamp}_${seq}_$randomPart';
  }

  /// Variant for loop-based generation — also includes the loop index so even
  /// if generate() is called for multiple prefixes at the same instant the IDs
  /// are distinguishable by both sequence AND index.
  static String generateWithIndex(String prefix, int index) {
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    final seq = _seq++;
    final randomPart = _random.nextInt(0xFFFFFF).toRadixString(16).padLeft(6, '0');
    return '${prefix}_${timestamp}_${seq}_${index}_$randomPart';
  }
}
