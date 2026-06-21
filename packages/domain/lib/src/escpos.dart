/// ESC/POS renderer for [TicketDoc].
///
/// Pure Dart, no I/O — transports (network/Bluetooth drivers) just write
/// the returned bytes. Output targets the common Epson command subset that
/// virtually every cheap thermal printer understands.
library;

import 'dart:convert';

import 'package:gbk_codec/gbk_codec.dart';

import 'ticket.dart';

class EscPos {
  /// Characters per line: 32 fits 58mm paper, 48 fits 80mm.
  static const width58mm = 32;
  static const width80mm = 48;

  static const _esc = 0x1B;
  static const _gs = 0x1D;
  static const _fs = 0x1C;
  static const _lf = 0x0A;

  /// Renders [doc] to printer bytes for a paper [widthChars] wide, encoding
  /// text per [charset] (see [TicketCharset]).
  static List<int> encode(
    TicketDoc doc, {
    required int widthChars,
    TicketCharset charset = TicketCharset.western,
  }) {
    final out = <int>[_esc, 0x40]; // ESC @ — initialize
    if (charset == TicketCharset.chinese) {
      out.addAll([_fs, 0x26]); // FS & — enter Chinese (multi-byte) mode
    }
    for (final op in doc.ops) {
      switch (op) {
        case TicketText(:final text, :final style):
          for (final line in _wrap(text, _effectiveWidth(widthChars, style))) {
            _writeLine(out, line, style, charset);
          }
        case TicketRow():
          for (final line in _layoutRow(op, widthChars)) {
            _writeLine(out, line, op.style, charset);
          }
        case TicketDivider():
          _writeLine(out, '-' * widthChars, TicketStyle.plain, charset);
        case TicketFeed(:final lines):
          out.addAll([_esc, 0x64, lines]); // ESC d n — feed n lines
        case TicketCut():
          out.addAll([_gs, 0x56, 0x42, 0x00]); // GS V — feed and partial cut
        case TicketKickDrawer():
          // ESC p 0 25 250 — pulse drawer pin 2 (~25ms on / ~250ms off).
          out.addAll([_esc, 0x70, 0x00, 0x19, 0xFA]);
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
        case TicketKickDrawer():
          break;
      }
    }
    return lines.join('\n');
  }

  // --- Internals ---

  /// Double-width characters take two columns, halving the line capacity.
  static int _effectiveWidth(int widthChars, TicketStyle style) =>
      style.doubleWidth ? widthChars ~/ 2 : widthChars;

  static void _writeLine(
    List<int> out,
    String line,
    TicketStyle style,
    TicketCharset charset,
  ) {
    out.addAll([_esc, 0x61, style.align.index]); // ESC a n — alignment
    out.addAll([_esc, 0x45, style.bold ? 1 : 0]); // ESC E n — bold
    final size = (style.doubleWidth ? 0x10 : 0) | (style.doubleHeight ? 1 : 0);
    out.addAll([_gs, 0x21, size]); // GS ! n — character size
    out.addAll(_bytes(line, charset));
    out.add(_lf);
  }

  static List<int> _bytes(String line, TicketCharset charset) {
    switch (charset) {
      // Thermal printers default to code page 437, so anything beyond ASCII
      // prints as '?'.
      case TicketCharset.western:
        return ascii.encode(line.replaceAll(RegExp(r'[^\x00-\x7F]'), '?'));
      // GBK (a superset of ASCII) for mixed Latin + Chinese in one pass. The
      // gbk_codec returns a multi-byte glyph as one combined int (e.g. 中 ->
      // 0xD6D0), so split those into high/low bytes; unmappable chars fall back
      // to '?' rather than throwing.
      case TicketCharset.chinese:
        final out = <int>[];
        for (final rune in line.runes) {
          if (rune < 0x80) {
            out.add(rune);
            continue;
          }
          try {
            for (final code in gbk.encode(String.fromCharCode(rune))) {
              if (code > 0xFF) {
                out.add((code >> 8) & 0xFF);
                out.add(code & 0xFF);
              } else {
                out.add(code);
              }
            }
          } catch (_) {
            out.add(0x3F); // '?'
          }
        }
        return out;
    }
  }

  static List<String> _layoutRow(TicketRow row, int widthChars) {
    final w = _effectiveWidth(widthChars, row.style);
    final right = row.right;
    final leftW = _displayWidth(row.left);
    final rightW = _displayWidth(right);
    // Fits on one line: pad the gap. Otherwise wrap the left column and
    // right-align the right column on its own line below. Padding uses printer
    // column width (CJK glyphs occupy two columns) so amounts line up.
    if (leftW + rightW + 1 <= w) {
      return ['${row.left}${' ' * (w - leftW - rightW)}$right'];
    }
    return [..._wrap(row.left, w), _padLeftToWidth(right, w)];
  }

  static String _aligned(String line, int width, TicketAlign align) =>
      switch (align) {
        TicketAlign.left => line,
        TicketAlign.center =>
          ' ' * ((width - _displayWidth(line)).clamp(0, width) ~/ 2) + line,
        TicketAlign.right => _padLeftToWidth(line, width),
      };

  static String _padLeftToWidth(String s, int width) {
    final pad = width - _displayWidth(s);
    return pad > 0 ? ' ' * pad + s : s;
  }

  /// Printer column width of [s]: CJK / fullwidth glyphs take two columns.
  static int _displayWidth(String s) {
    var width = 0;
    for (final r in s.runes) {
      width += _isWide(r) ? 2 : 1;
    }
    return width;
  }

  static bool _isWide(int r) =>
      (r >= 0x1100 && r <= 0x115F) || // Hangul Jamo
      (r >= 0x2E80 && r <= 0xA4CF) || // CJK radicals … Yi
      (r >= 0xAC00 && r <= 0xD7A3) || // Hangul syllables
      (r >= 0xF900 && r <= 0xFAFF) || // CJK compatibility ideographs
      (r >= 0xFE30 && r <= 0xFE4F) || // CJK compatibility forms
      (r >= 0xFF00 && r <= 0xFF60) || // fullwidth forms
      (r >= 0xFFE0 && r <= 0xFFE6) ||
      (r >= 0x20000 && r <= 0x3FFFD); // CJK extension B+

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
