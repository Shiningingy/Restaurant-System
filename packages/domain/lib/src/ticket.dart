/// Device-independent ticket document model.
///
/// Templates (receipt_templates.dart) build a [TicketDoc]; the ESC/POS
/// encoder (escpos.dart) turns it into printer bytes for a given paper
/// width. Keeping the document abstract means templates never know about
/// escape codes and can be unit-tested as plain text.
library;

enum TicketAlign { left, center, right }

/// Character set the ESC/POS encoder uses for a print job.
///
///  - [western]: ASCII; non-ASCII characters print as `?` (the historical
///    behaviour — fine for Latin menus).
///  - [chinese]: enables the printer's Chinese mode (`FS &`) and encodes text
///    as GBK, so Chinese (and other CJK) names print correctly.
///  - [auto]: decides per ticket — Chinese mode when the text actually contains
///    CJK characters, otherwise Western. Lets the app pick the encoder so the
///    user never has to choose. The default.
enum TicketCharset { western, chinese, auto }

class TicketStyle {
  final bool bold;
  final bool doubleWidth;
  final bool doubleHeight;
  final TicketAlign align;

  const TicketStyle({
    this.bold = false,
    this.doubleWidth = false,
    this.doubleHeight = false,
    this.align = TicketAlign.left,
  });

  static const plain = TicketStyle();
  static const title = TicketStyle(
    bold: true,
    doubleWidth: true,
    doubleHeight: true,
    align: TicketAlign.center,
  );
  static const big = TicketStyle(doubleHeight: true);
  static const emphasized = TicketStyle(bold: true);
  static const centered = TicketStyle(align: TicketAlign.center);
}

sealed class TicketOp {
  const TicketOp();
}

/// A paragraph of text; wrapped to the paper width by the encoder.
class TicketText extends TicketOp {
  final String text;
  final TicketStyle style;

  const TicketText(this.text, {this.style = TicketStyle.plain});
}

/// A two-column line: [left] flushed left, [right] flushed right,
/// padded with spaces to the paper width (e.g. item name / price).
class TicketRow extends TicketOp {
  final String left;
  final String right;
  final TicketStyle style;

  const TicketRow(this.left, this.right, {this.style = TicketStyle.plain});
}

/// A full-width dashed rule.
class TicketDivider extends TicketOp {
  const TicketDivider();
}

class TicketFeed extends TicketOp {
  final int lines;

  const TicketFeed([this.lines = 1]);
}

class TicketCut extends TicketOp {
  const TicketCut();
}

/// Pulses the cash drawer connected to the (receipt) printer's kick port.
class TicketKickDrawer extends TicketOp {
  const TicketKickDrawer();
}

class TicketDoc {
  final List<TicketOp> ops;

  const TicketDoc(this.ops);
}
