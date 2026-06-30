/// Every user-facing string the [KioskSurface] renders, so the one shared
/// widget can be plain English on the merchant display ([KioskLabels.en]) or
/// fully localized in the customer app (built from its `AppLocalizations`).
///
/// The function fields cover strings that interpolate a count or an amount.
/// [KioskLabels.en] uses static tear-offs so it can stay `const`.
class KioskLabels {
  final String loadingMenu;
  final String retry;
  final String back;

  /// Header title shown when the business name is empty.
  final String headerFallbackTitle;
  final String cancel;
  final String cartEmpty;
  final String reviewOrder;

  /// App-bar title of the review/cart screen.
  final String reviewTitle;
  final String addMore;
  final String payAtCounter;

  /// Label on the place-order button while the order is being submitted.
  final String placing;
  final String payHereSoon;
  final String subtotal;
  final String total;

  /// Tip selector: section title, the "No tip" button, the custom-amount
  /// button, its field hint, and the breakdown row label.
  final String tipTitle;
  final String noTip;
  final String tipCustom;
  final String tipCustomHint;
  final String tip;
  final String orderPlaced;
  final String yourNumber;
  final String payAtCounterNote;
  final String done;
  final String addToOrder;
  final String submitFailed;

  /// "2 items · $24.00" — the cart-bar summary.
  final String Function(int count, String total) cartSummary;

  /// "Service (13.00%)" given the formatted percent.
  final String Function(String pct) service;

  /// "Tax (13.00%)" given the formatted percent.
  final String Function(String pct) tax;

  /// "Add to order · +$2.00" when modifiers add a charge.
  final String Function(String extra) addToOrderExtra;

  /// "Add to order · $14.99" — the running line total on the popup's button.
  final String Function(String total) addToOrderTotal;

  const KioskLabels({
    required this.loadingMenu,
    required this.retry,
    required this.back,
    required this.headerFallbackTitle,
    required this.cancel,
    required this.cartEmpty,
    required this.reviewOrder,
    required this.reviewTitle,
    required this.addMore,
    required this.payAtCounter,
    required this.placing,
    required this.payHereSoon,
    required this.subtotal,
    required this.total,
    required this.tipTitle,
    required this.noTip,
    required this.tipCustom,
    required this.tipCustomHint,
    required this.tip,
    required this.orderPlaced,
    required this.yourNumber,
    required this.payAtCounterNote,
    required this.done,
    required this.addToOrder,
    required this.submitFailed,
    required this.cartSummary,
    required this.service,
    required this.tax,
    required this.addToOrderExtra,
    required this.addToOrderTotal,
  });

  /// The merchant display's wording — plain English, exactly as before the
  /// widget was shared.
  const KioskLabels.en()
    : loadingMenu = 'Loading menu…',
      retry = 'Retry',
      back = 'Back',
      headerFallbackTitle = 'Order here',
      cancel = 'Cancel',
      cartEmpty = 'Your cart is empty',
      reviewOrder = 'Review order',
      reviewTitle = 'Your order',
      addMore = 'Add more',
      payAtCounter = 'Pay at counter',
      placing = 'Placing…',
      payHereSoon = 'Pay here (soon)',
      subtotal = 'Subtotal',
      total = 'Total',
      tipTitle = 'Add a tip?',
      noTip = 'No tip',
      tipCustom = 'Custom',
      tipCustomHint = 'Tip amount',
      tip = 'Tip',
      orderPlaced = 'Order placed!',
      yourNumber = 'Your number',
      payAtCounterNote = 'Please pay at the counter.',
      done = 'Done',
      addToOrder = 'Add to order',
      submitFailed = 'Could not place the order. Please ask staff.',
      cartSummary = _enCartSummary,
      service = _enService,
      tax = _enTax,
      addToOrderExtra = _enAddToOrderExtra,
      addToOrderTotal = _enAddToOrderTotal;

  static String _enCartSummary(int count, String total) =>
      '$count item${count == 1 ? '' : 's'}  ·  $total';
  static String _enService(String pct) => 'Service ($pct%)';
  static String _enTax(String pct) => 'Tax ($pct%)';
  static String _enAddToOrderExtra(String extra) => 'Add to order  ·  +$extra';
  static String _enAddToOrderTotal(String total) => 'Add to order  ·  $total';
}
