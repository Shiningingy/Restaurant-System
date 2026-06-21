/// The name of the window-to-window method channel the POS window and the
/// customer-display / kiosk sub-window talk over. Defined on its own (no heavy
/// imports) so the sub-window — which owns no database — can reference it
/// without pulling in the POS provider graph.
///
/// The two windows are separate Flutter engines (separate isolates): nothing
/// is shared in memory, so every menu push and every submitted kiosk order
/// crosses as a message on this bidirectional channel.
const kCustomerDisplayChannel = 'pos/customer_display';
