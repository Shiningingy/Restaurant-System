/// Shared design system for the Restaurant System apps.
///
/// One source of truth for the look every surface shares — the merchant POS,
/// the customer preorder app, and the customer display / kiosk. It codifies the
/// design handoff: stock Material 3 from the deepOrange seed, plus the POS
/// touch-target floor, tabular money figures, the explicit corner scale, and
/// the [PosStatusColors] order-state / brand-mark tokens.
library;

export 'src/brand_mark.dart';
export 'src/pos_status_colors.dart';
export 'src/pos_theme.dart';
