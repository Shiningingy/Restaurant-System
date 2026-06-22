import 'package:restaurant_domain/restaurant_domain.dart';
import 'package:test/test.dart';

void main() {
  group('EscPos.encode', () {
    test('starts with initialize and ends a text line with LF', () {
      final bytes = EscPos.encode(
        const TicketDoc([TicketText('HI')]),
        widthChars: 32,
      );
      expect(bytes.sublist(0, 2), [0x1B, 0x40]); // ESC @
      expect(bytes.last, 0x0A);
      // Alignment, bold and size are reset explicitly per line.
      expect(bytes, containsAllInOrder([0x1B, 0x61, 0x00])); // ESC a left
      expect(bytes, containsAllInOrder([0x1B, 0x45, 0x00])); // ESC E off
      expect(bytes, containsAllInOrder([0x1D, 0x21, 0x00])); // GS ! normal
      expect(bytes, containsAllInOrder([0x48, 0x49])); // "HI"
    });

    test('emits style commands for title text', () {
      final bytes = EscPos.encode(
        const TicketDoc([TicketText('X', style: TicketStyle.title)]),
        widthChars: 32,
      );
      expect(bytes, containsAllInOrder([0x1B, 0x61, 0x01])); // centered
      expect(bytes, containsAllInOrder([0x1B, 0x45, 0x01])); // bold
      expect(bytes, containsAllInOrder([0x1D, 0x21, 0x11])); // double w+h
    });

    test('emits feed and cut commands', () {
      final bytes = EscPos.encode(
        const TicketDoc([TicketFeed(3), TicketCut()]),
        widthChars: 32,
      );
      expect(bytes, containsAllInOrder([0x1B, 0x64, 3])); // ESC d 3
      expect(bytes, containsAllInOrder([0x1D, 0x56, 0x42, 0x00])); // GS V
    });

    test('replaces non-ASCII characters instead of crashing', () {
      final bytes = EscPos.encode(
        const TicketDoc([TicketText('café')]),
        widthChars: 32,
      );
      expect(bytes, containsAllInOrder('caf?'.codeUnits));
    });

    test('chinese charset enters Chinese mode and encodes GBK, not "?"', () {
      final bytes = EscPos.encode(
        const TicketDoc([TicketText('中A')]),
        widthChars: 32,
        charset: TicketCharset.chinese,
      );
      expect(bytes, containsAllInOrder([0x1C, 0x26])); // FS & — Chinese mode
      expect(bytes, containsAllInOrder([0xD6, 0xD0])); // 中 in GBK
      expect(bytes, containsAllInOrder([0x41])); // 'A' passes through as ASCII
      expect(bytes, isNot(contains(0x3F))); // no '?' fallback
    });

    test('western charset (default) leaves Chinese as "?" and no FS &', () {
      final bytes = EscPos.encode(
        const TicketDoc([TicketText('中')]),
        widthChars: 32,
      );
      expect(bytes, contains(0x3F));
      expect(bytes, isNot(containsAllInOrder([0x1C, 0x26])));
    });

    test('emits a cash-drawer kick pulse', () {
      final bytes = EscPos.encode(
        const TicketDoc([TicketKickDrawer()]),
        widthChars: 32,
      );
      expect(bytes, containsAllInOrder([0x1B, 0x70, 0x00, 0x19, 0xFA]));
    });

    test('auto charset uses Chinese mode + GBK when the ticket has CJK', () {
      final bytes = EscPos.encode(
        const TicketDoc([TicketText('中A')]),
        widthChars: 32,
        charset: TicketCharset.auto,
      );
      expect(bytes, containsAllInOrder([0x1C, 0x26])); // FS & — Chinese mode
      expect(bytes, containsAllInOrder([0xD6, 0xD0])); // 中 in GBK
      expect(bytes, isNot(contains(0x3F)));
    });

    test('auto charset with pure ASCII matches Western (no FS &)', () {
      const doc = TicketDoc([TicketText('Burger 12')]);
      final auto =
          EscPos.encode(doc, widthChars: 32, charset: TicketCharset.auto);
      final western = EscPos.encode(doc, widthChars: 32);
      expect(auto, equals(western));
      expect(auto, isNot(containsAllInOrder([0x1C, 0x26])));
    });

    test('auto detects CJK inside a row, not just plain text', () {
      final bytes = EscPos.encode(
        const TicketDoc([TicketRow('包子', r'$2.00')]),
        widthChars: 32,
        charset: TicketCharset.auto,
      );
      expect(bytes, containsAllInOrder([0x1C, 0x26]));
    });

    test('gbkEncode passes ASCII through and encodes CJK', () {
      expect(EscPos.gbkEncode('A中'), [0x41, 0xD6, 0xD0]);
    });
  });

  group('chineseDiagnosticBytes', () {
    final bytes = chineseDiagnosticBytes(widthChars: 32);

    test('includes the FS & block, GBK and UTF-8 of 中, and a cut', () {
      expect(bytes.sublist(0, 2), [0x1B, 0x40]); // ESC @
      expect(bytes, containsAllInOrder([0x1C, 0x26])); // FS & (block A/D)
      expect(bytes, containsAllInOrder([0xD6, 0xD0])); // 中 in GBK
      expect(bytes, containsAllInOrder([0xE4, 0xB8, 0xAD])); // 中 in UTF-8
      expect(bytes, containsAllInOrder([0x1C, 0x43, 0x01])); // FS C 1 (block D)
      expect(bytes, containsAllInOrder([0x1D, 0x56, 0x42, 0x00])); // GS V cut
    });

    test('labels each block in plain ASCII', () {
      expect(bytes, containsAllInOrder('A) FS& + GBK'.codeUnits));
      expect(bytes, containsAllInOrder('C) UTF-8'.codeUnits));
    });
  });

  group('EscPos.renderPlainText', () {
    test('pads a row to the full width', () {
      final text = EscPos.renderPlainText(
        const TicketDoc([TicketRow('Burger', r'$10.00')]),
        widthChars: 32,
      );
      expect(text.length, 32);
      expect(text, startsWith('Burger'));
      expect(text, endsWith(r'$10.00'));
    });

    test('right-aligns an amount accounting for CJK double-width glyphs', () {
      final text = EscPos.renderPlainText(
        const TicketDoc([TicketRow('包子', r'$2.00')]),
        widthChars: 32,
      );
      // 2 CJK glyphs = 4 columns, amount = 5 columns -> 23 spaces between.
      expect(text, '包子${' ' * 23}\$2.00');
    });

    test('wraps a long left column and right-aligns the amount below', () {
      final text = EscPos.renderPlainText(
        const TicketDoc([
          TicketRow(
            '2 x Extra Large Double Bacon Cheeseburger Deluxe',
            r'$25.00',
          ),
        ]),
        widthChars: 32,
      );
      final lines = text.split('\n');
      expect(lines.length, greaterThan(1));
      for (final line in lines) {
        expect(line.length, lessThanOrEqualTo(32));
      }
      expect(lines.last, r'$25.00'.padLeft(32));
    });

    test('word-wraps text at the paper width', () {
      final text = EscPos.renderPlainText(
        const TicketDoc([
          TicketText('the quick brown fox jumps over the lazy dog'),
        ]),
        widthChars: 16,
      );
      for (final line in text.split('\n')) {
        expect(line.length, lessThanOrEqualTo(16));
      }
      expect(text.replaceAll('\n', ' '),
          'the quick brown fox jumps over the lazy dog');
    });

    test('double-width text wraps at half the paper width', () {
      final text = EscPos.renderPlainText(
        const TicketDoc([
          TicketText('ABCDEFGHIJ KLMN', style: TicketStyle(doubleWidth: true)),
        ]),
        widthChars: 20,
      );
      for (final line in text.split('\n')) {
        expect(line.length, lessThanOrEqualTo(10));
      }
    });

    test('centers within the width', () {
      final text = EscPos.renderPlainText(
        const TicketDoc([TicketText('HI', style: TicketStyle.centered)]),
        widthChars: 10,
      );
      expect(text, '    HI');
    });

    test('divider spans the width', () {
      final text = EscPos.renderPlainText(
        const TicketDoc([TicketDivider()]),
        widthChars: 32,
      );
      expect(text, '-' * 32);
    });
  });
}
