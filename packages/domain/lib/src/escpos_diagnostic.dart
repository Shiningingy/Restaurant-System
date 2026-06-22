/// A one-off ESC/POS diagnostic page for Chinese printing.
///
/// Different thermal printers want Chinese in different ways (and some have no
/// Chinese font at all). Since we can't ask a printer what it supports, this
/// prints a known sample several ways — each under an ASCII label — so a human
/// can read which block renders correctly and we lock that printer to it.
library;

import 'dart:convert';

import 'escpos.dart';

/// Builds the raw bytes for the Chinese diagnostic page, sized for [widthChars].
///
/// Built as raw bytes (not a [TicketDoc]) because each block needs a *different*
/// command + encoding, which is below the uniform-charset document model. Every
/// block is preceded by `ESC @` (reset) so a command one printer misreads can't
/// corrupt the blocks after it.
List<int> chineseDiagnosticBytes({required int widthChars}) {
  const esc = 0x1B, fs = 0x1C, gs = 0x1D, lf = 0x0A;
  const sample = '中文测试 ABC'; // CJK + ASCII so both are visible
  final out = <int>[esc, 0x40]; // ESC @ — initialize

  void asciiLine(String s) {
    out.addAll(ascii.encode(s.replaceAll(RegExp(r'[^\x00-\x7F]'), '?')));
    out.add(lf);
  }

  void reset() => out.addAll([esc, 0x40]); // back to a clean state

  asciiLine('CHINESE DIAGNOSTIC');
  asciiLine('Which block below is readable?');
  asciiLine('-' * widthChars);

  // A) FS& + GBK — our current path (Epson Simplified spec).
  asciiLine('A) FS& + GBK (current)');
  out.addAll([fs, 0x26]); // FS & — enter Chinese mode
  out.addAll(EscPos.gbkEncode(sample));
  out.add(lf);
  out.addAll([fs, 0x2E]); // FS . — cancel Chinese mode
  reset();

  // B) GBK with no FS& — printers already sitting in GB mode.
  asciiLine('B) GBK only (no FS&)');
  out.addAll(EscPos.gbkEncode(sample));
  out.add(lf);
  reset();

  // C) raw UTF-8 — printers/settings expecting UTF-8.
  asciiLine('C) UTF-8 (no FS&)');
  out.addAll(utf8.encode(sample));
  out.add(lf);
  reset();

  // D) FS C 1 then FS& + GBK — printers needing the code system selected first.
  asciiLine('D) FS C 1 + FS& + GBK');
  out.addAll([fs, 0x43, 0x01]); // FS C n — select Kanji/Chinese code system
  out.addAll([fs, 0x26]);
  out.addAll(EscPos.gbkEncode(sample));
  out.add(lf);
  out.addAll([fs, 0x2E]);
  reset();

  asciiLine('-' * widthChars);
  asciiLine('Sample: zhong wen ce shi');
  asciiLine('Tell us which letter looks right.');

  out.addAll([esc, 0x64, 0x04]); // ESC d 4 — feed 4 lines
  out.addAll([gs, 0x56, 0x42, 0x00]); // GS V — partial cut
  return out;
}
