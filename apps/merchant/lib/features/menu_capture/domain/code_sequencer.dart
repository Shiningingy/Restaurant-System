// Makes a captured item code unique against codes already in use, by bumping
// its trailing number — so sweeping several items doesn't produce `AX1, AX1`
// but `AX1, AX2`. Collision-only: a code that isn't taken is returned as-is.

final _trailingDigits = RegExp(r'^(.*?)(\d+)$');

/// Returns [desired] if it's empty or not in [taken]; otherwise the next code
/// whose trailing integer is incremented (zero-pad width preserved until it
/// must grow), or `desired2`, `desired3`… when there's no trailing digit.
String nextUniqueCode(String desired, Set<String> taken) {
  if (desired.isEmpty || !taken.contains(desired)) return desired;

  final match = _trailingDigits.firstMatch(desired);
  if (match != null) {
    final prefix = match.group(1)!;
    final digits = match.group(2)!;
    final width = digits.length;
    var n = int.parse(digits);
    String candidate;
    do {
      n++;
      candidate = '$prefix${n.toString().padLeft(width, '0')}';
    } while (taken.contains(candidate));
    return candidate;
  }

  // No trailing number — append 2, 3, …
  var n = 2;
  while (taken.contains('$desired$n')) {
    n++;
  }
  return '$desired$n';
}
