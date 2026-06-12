/// ESC/POS renderer for [TicketDoc].
///
/// Pure Dart, no I/O — transports (network/Bluetooth drivers) just write
/// the returned bytes. Output targets the common Epson command subset that
/// virtually every cheap thermal printer understands.
library;

import 'dart:convert';

import 'ticket.dart';

class EscPos {
  /// Characters per line: 32 fits 58mm paper, 48 fits 80mm.
  static const width58mm = 32;
  static const width80mm = 48;

  static const _esc = 0x1B;
  static const _gs = 0x1D;
  static const _lf = 0x0A;

  /// Renders [doc] to printer bytes for a paper [widthChars] wide.
  static List<int> encode(TicketDoc doc, {required int widthChars}) {
    final out = <int>[_esc, 0x40]; // ESC @ — initialize
    for (final op in doc.ops) {
      switch (op) {
        case TicketText(:final text, :final style):
          for (final line in _wrap(text, _effectiveWidth(widthChars, style))) {
            _writeLine(out, line, style);
          }
        case TicketRow():
          for (final line in _layoutRow(op, widthChars)) {
            _writeLine(out, line, op.style);
          }
        case TicketDivider():
          _writeLine(out, '-' * widthChars, TicketStyle.plain);
        case TicketFeed(:final lines):
          out.addAll([_esc, 0x64, lines]); // ESC d n — feed n lines
        case TicketCut():
          out.addAll([_gs, 0x56, 0x42, 0x00]); // GS V — feed and partial cut
      }
    }
    return out;
  }

  /// Renders [doc] as plain text — used for previews and template tests.
  static String renderPlainText(TicketDoc doc, {required int widthChars}) {
    final lines = <String>[];
    for (final op in doc.ops) {
      switch (op) {
        case TicketText(:final text, :final style):
          final w = _effectiveWidth(widthChars, style);
          lines.addAll(_wrap(text, w).map((l) => _aligned(l, w, style.align)));
        case TicketRow():
          lines.addAll(_layoutRow(op, widthChars));
        case TicketDivider():
          lines.add('-' * widthChars);
        case TicketFeed(lines: final count):
          lines.addAll(List.filled(count, ''));
        case TicketCut():
          break;
      }
    }
    return lines.join('\n');
  }

  // --- Internals ---

  /// Double-width characters take two columns, halving the line capacity.
  static int _effectiveWidth(int widthChars, TicketStyle style) =>
      style.doubleWidth ? widthChars ~/ 2 : widthChars;

  static void _writeLine(List<int> out, String line, TicketStyle style) {
    out.addAll([_esc, 0x61, style.align.index]); // ESC a n — alignment
    out.addAll([_esc, 0x45, style.bold ? 1 : 0]); // ESC E n — bold
    final size = (style.doubleWidth ? 0x10 : 0) | (style.doubleHeight ? 1 : 0);
    out.addAll([_gs, 0x21, size]); // GS ! n — character size
    out.addAll(_bytes(line));
    out.add(_lf);
  }

  /// ASCII-safe bytes: thermal printers default to code page 437, so
  /// anything beyond ASCII prints as '?' until codepage support lands.
  static List<int> _bytes(String line) =>
      ascii.encode(line.replaceAll(RegExp(r'[^\x00-\x7F]'), '?'));

  static List<String> _layoutRow(TicketRow row, int widthChars) {
    final w = _effectiveWidth(widthChars, row.style);
    final right = row.right;
    // Fits on one line: pad the gap. Otherwise wrap the left column and
    // right-align the right column on its own line below.
    if (row.left.length + right.length + 1 <= w) {
      return ['${row.left}${' ' * (w - row.left.length - right.length)}$right'];
    }
    return [..._wrap(row.left, w), right.padLeft(w)];
  }

  static String _aligned(String line, int width, TicketAlign align) =>
      switch (align) {
        TicketAlign.left => line,
        TicketAlign.center =>
          ' ' * ((width - line.length).clamp(0, width) ~/ 2) + line,
        TicketAlign.right => line.padLeft(width),
      };

  /// Word-wraps [text] to [width] columns; words longer than a line are
  /// hard-split.
  static List<String> _wrap(String text, int width) {
    final lines = <String>[];
    for (final paragraph in text.split('\n')) {
      var current = StringBuffer();
      for (final word in paragraph.split(' ')) {
        var w = word;
        while (w.length > width) {
          if (current.isNotEmpty) {
            lines.add(current.toString());
            current = StringBuffer();
          }
          lines.add(w.substring(0, width));
          w = w.substring(width);
        }
        if (current.isEmpty) {
          current.write(w);
        } else if (current.length + 1 + w.length <= width) {
          current.write(' $w');
        } else {
          lines.add(current.toString());
          current = StringBuffer(w);
        }
      }
      lines.add(current.toString());
    }
    return lines;
  }
}
