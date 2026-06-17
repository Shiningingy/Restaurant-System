import 'package:flutter_test/flutter_test.dart';
import 'package:merchant/features/menu_capture/domain/code_sequencer.dart';

void main() {
  test('returns the code unchanged when not taken or empty', () {
    expect(nextUniqueCode('A01', {'B02'}), 'A01');
    expect(nextUniqueCode('', {''}), '');
    expect(nextUniqueCode('', {'A01'}), '');
  });

  test('bumps the trailing integer, preserving zero-pad width', () {
    expect(nextUniqueCode('A01', {'A01'}), 'A02');
    expect(nextUniqueCode('AX1', {'AX1'}), 'AX2');
    expect(nextUniqueCode('A09', {'A09'}), 'A10');
    expect(nextUniqueCode('7', {'7'}), '8');
  });

  test('skips over codes already taken', () {
    expect(nextUniqueCode('A01', {'A01', 'A02', 'A03'}), 'A04');
  });

  test('width grows past the padding when needed', () {
    expect(nextUniqueCode('A99', {'A99'}), 'A100');
  });

  test('appends 2,3,… when there is no trailing digit', () {
    expect(nextUniqueCode('Soup', {'Soup'}), 'Soup2');
    expect(nextUniqueCode('Soup', {'Soup', 'Soup2'}), 'Soup3');
  });

  test('simulates a sweep accumulating into the taken set', () {
    final used = <String>{};
    final out = <String>[];
    for (final desired in ['A01', 'A01', 'A01', 'A02']) {
      final code = nextUniqueCode(desired, used);
      used.add(code);
      out.add(code);
    }
    expect(out, ['A01', 'A02', 'A03', 'A04']);
  });
}
