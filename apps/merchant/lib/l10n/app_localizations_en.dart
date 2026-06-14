// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Restaurant System';

  @override
  String get navOrders => 'Orders';

  @override
  String get navMenu => 'Menu';

  @override
  String get navInbox => 'Inbox';

  @override
  String get navReports => 'Reports';

  @override
  String get navSettings => 'Settings';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonSave => 'Save';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonAdd => 'Add';

  @override
  String get commonEdit => 'Edit';

  @override
  String get commonClose => 'Close';

  @override
  String get commonRemove => 'Remove';

  @override
  String get commonDone => 'Done';

  @override
  String get orderDineIn => 'Dine-in';

  @override
  String get orderTakeout => 'Takeout';

  @override
  String get orderOnline => 'Online';

  @override
  String orderTableLabel(String label) {
    return 'Table $label';
  }

  @override
  String get payCash => 'Cash';

  @override
  String get payCard => 'Card';

  @override
  String get payCardKeyed => 'Card (keyed)';

  @override
  String get ordersTitle => 'Open Orders';

  @override
  String get ordersEmpty =>
      'No open orders — start a dine-in or takeout order.';

  @override
  String ordersLoadFailed(String error) {
    return 'Failed to load orders: $error';
  }

  @override
  String get noTablesYet => 'No tables yet — add tables in Settings.';

  @override
  String get pickTable => 'Pick a table';

  @override
  String get ordVoidOrder => 'Void order';

  @override
  String get ordDineInTitle => 'Dine-in order';

  @override
  String get ordTakeoutTitle => 'Takeout order';

  @override
  String get ordOnlineTitle => 'Online order';

  @override
  String get ordOrderTitle => 'Order';

  @override
  String get ordVoidConfirmTitle => 'Void this order?';

  @override
  String get ordVoidConfirmBody => 'The order is kept in history as voided.';

  @override
  String get ordKeep => 'Keep';

  @override
  String get ordNoMenuYet => 'No menu yet — add categories and items in Menu.';

  @override
  String get ordTapToAdd => 'Tap menu items to add them.';

  @override
  String get ordVoidLine => 'Void line';

  @override
  String get ordDecrease => 'Decrease';

  @override
  String ordQtyMultiplier(int qty) {
    return 'x$qty';
  }

  @override
  String get ordSubtotal => 'Subtotal';

  @override
  String ordTaxPercent(String rate) {
    return 'Tax ($rate%)';
  }

  @override
  String get ordTotal => 'Total';

  @override
  String ordPaidMethod(String method) {
    return 'Paid — $method';
  }

  @override
  String ordTipSuffix(String tip) {
    return ' (tip $tip)';
  }

  @override
  String get ordBalanceDue => 'Balance due';

  @override
  String get ordReprintKitchenTicket => 'Reprint kitchen ticket';

  @override
  String get ordSendToKitchen => 'Send to kitchen';

  @override
  String ordPayAmount(String amount) {
    return 'Pay $amount';
  }

  @override
  String get ordClosed => 'Closed';

  @override
  String get ordNoPrinterConfigured =>
      'No printer configured — set one up in Settings.';

  @override
  String get ordKitchenTicketQueued => 'Kitchen ticket queued.';

  @override
  String get ordPartialPaymentRecorded =>
      'Partial payment recorded — order stays open.';

  @override
  String get ordCardDeclined => 'Card declined — not recorded as paid.';

  @override
  String ordPaymentFailed(String message) {
    return 'Payment failed: $message';
  }

  @override
  String get menuTitle => 'Menu';

  @override
  String get menuItems => 'Items';

  @override
  String get menuModifierGroups => 'Modifier groups';

  @override
  String get menuHiddenFromOrderScreen => 'Hidden from order screen';

  @override
  String get menuCategory => 'Category';

  @override
  String get menuCreateCategoryToStart =>
      'Create a category to start your menu.';

  @override
  String get menuNewCategory => 'New category';

  @override
  String get menuEditCategory => 'Edit category';

  @override
  String get menuName => 'Name';

  @override
  String get menuVisibleOnOrderScreen => 'Visible on order screen';

  @override
  String get menuItem => 'Item';

  @override
  String get menuNoItemsInCategory => 'No items in this category yet.';

  @override
  String get menuNewItem => 'New item';

  @override
  String get menuEditItem => 'Edit item';

  @override
  String get menuPrice => 'Price';

  @override
  String get modGroup => 'Group';

  @override
  String get modGroupsEmpty =>
      'Modifier groups (e.g. \"Size\", \"Add-ons\") appear here.';

  @override
  String get modModifier => 'Modifier';

  @override
  String get modEditGroup => 'Edit group';

  @override
  String get modDeleteGroup => 'Delete group';

  @override
  String get modOptionalPickOne => 'Optional, pick one';

  @override
  String modOptionalUpTo(int n) {
    return 'Optional, up to $n';
  }

  @override
  String modRequiredPick(int n) {
    return 'Required, pick $n';
  }

  @override
  String modRequiredPickRange(int min, int max) {
    return 'Required, pick $min-$max';
  }

  @override
  String get modNewGroup => 'New modifier group';

  @override
  String get modGroupNameLabel => 'Name (e.g. Size, Add-ons)';

  @override
  String get modMinPicks => 'Min picks';

  @override
  String get modMaxPicks => 'Max picks';

  @override
  String get modNewModifier => 'New modifier';

  @override
  String get modEditModifier => 'Edit modifier';

  @override
  String get modName => 'Name';

  @override
  String get modPriceChange => 'Price change';

  @override
  String get modPriceChangeHelper => 'Can be negative, e.g. -0.50';

  @override
  String modDeleteGroupConfirm(String name) {
    return 'Delete \"$name\"?';
  }

  @override
  String get modDeleteGroupBody =>
      'Items lose this group. Past orders are unaffected (they keep snapshots).';

  @override
  String get modAddToOrder => 'Add to order';

  @override
  String get modOptional => 'optional';

  @override
  String modUpTo(int n) {
    return 'up to $n';
  }

  @override
  String modPick(int n) {
    return 'pick $n';
  }

  @override
  String modPickRange(int min, int max) {
    return 'pick $min-$max';
  }

  @override
  String get pmtAmount => 'Amount';

  @override
  String get pmtTipOptional => 'Tip (optional)';

  @override
  String get pmtTipFromTerminal => 'Tip from terminal (optional)';

  @override
  String get pmtEnterValidAmount => 'Enter a valid amount.';

  @override
  String get pmtEnterValidTip => 'Enter a valid tip.';

  @override
  String pmtAmountExceedsBalance(String balance) {
    return 'Amount exceeds the balance ($balance).';
  }

  @override
  String pmtCollect(String amount) {
    return 'Collect $amount';
  }

  @override
  String pmtKeyAmountOnTerminal(String amount) {
    return 'Key $amount on the terminal';
  }

  @override
  String get pmtKeyOnTerminalBody =>
      'Enter the amount on the card terminal, then record the outcome shown on its screen.';

  @override
  String get pmtPartialPaymentHint => 'Partial payment — the order stays open.';

  @override
  String get pmtLowerToSplitHint => 'Lower the amount to split the bill.';

  @override
  String get pmtDeclined => 'Declined';

  @override
  String get pmtApproved => 'Approved';

  @override
  String get inboxTitle => 'Online orders';

  @override
  String get inboxPublishMenu => 'Publish menu';

  @override
  String get inboxDisabledHint =>
      'Set up your Supabase project in Settings to accept online preorders. The POS works fully without it.';

  @override
  String get inboxNewPreorders => 'New preorders';

  @override
  String get inboxNoNewPreorders => 'No new preorders.';

  @override
  String get inboxPreparing => 'Preparing';

  @override
  String get inboxNothingInProgress => 'Nothing in progress.';

  @override
  String get inboxMenuPublished => 'Menu published to your storefront.';

  @override
  String inboxPublishFailed(String error) {
    return 'Publish failed: $error';
  }

  @override
  String inboxError(String error) {
    return 'Error: $error';
  }

  @override
  String inboxCustomerPickup(String name, String time) {
    return '$name — pickup $time';
  }

  @override
  String inboxTotalPayAtPickup(String total) {
    return 'Total $total — pay at pickup';
  }

  @override
  String get inboxReject => 'Reject';

  @override
  String get inboxAccept => 'Accept';

  @override
  String get inboxAcceptedAdded => 'Accepted — added to orders.';

  @override
  String get inboxPreorderRejected => 'Preorder rejected.';

  @override
  String get inboxCustomerNotifiedReady => 'Customer notified: ready.';

  @override
  String get inboxMarkReady => 'Mark ready';

  @override
  String get repTitle => 'Reports';

  @override
  String get repPreviousDay => 'Previous day';

  @override
  String get repNextDay => 'Next day';

  @override
  String get repCollected => 'Collected';

  @override
  String get repItemSales => 'Item sales';

  @override
  String repItemQty(int qty) {
    return '${qty}x';
  }

  @override
  String get repOrderHistory => 'Order history';

  @override
  String get repNoClosedOrders => 'No closed orders on this day.';

  @override
  String get repOrders => 'Orders';

  @override
  String repOrdersVoided(int count) {
    return '$count voided';
  }

  @override
  String get repGrossSales => 'Gross sales';

  @override
  String repSubtotalValue(String amount) {
    return 'Subtotal $amount';
  }

  @override
  String get repTax => 'Tax';

  @override
  String get repTips => 'Tips';

  @override
  String repPaymentsCount(int count) {
    return '$count payments';
  }

  @override
  String repPaymentsCountTips(int count, String tips) {
    return '$count payments — tips $tips';
  }

  @override
  String get repTotalCollected => 'Total collected';

  @override
  String repOrderVoidedSuffix(String ref) {
    return '$ref — voided';
  }

  @override
  String repOrderVoidedParen(String ref) {
    return '$ref (voided)';
  }

  @override
  String repLineQtyName(int qty, String name) {
    return '$qty x $name';
  }

  @override
  String get repTotal => 'Total';

  @override
  String repTipValue(String amount) {
    return 'Tip $amount';
  }

  @override
  String get repReceiptQueued => 'Receipt queued.';

  @override
  String get repReprintReceipt => 'Reprint receipt';

  @override
  String get setLanguage => 'Language';

  @override
  String get setLanguageSystem => 'System default';

  @override
  String get setTax => 'Tax';

  @override
  String get setSalesTaxRate => 'Sales tax rate';

  @override
  String get setSalesTaxRateSubtitle =>
      'Applied to new orders; existing orders keep their rate.';

  @override
  String get setPayments => 'Payments';

  @override
  String get setCardTerminalManual => 'Card terminal: manual entry';

  @override
  String get setCardTerminalManualSubtitle =>
      'Staff key the amount on the standalone terminal and record the outcome. Semi-integrated Moneris Go support arrives once the Moneris Cloud API access is set up.';

  @override
  String get setPrinting => 'Printing';

  @override
  String get setTestPrint => 'Test print';

  @override
  String get setNetworkPrinter => 'Network printer';

  @override
  String setPrinterConfigured(String host, int port, String width) {
    return '$host:$port — ${width}mm paper';
  }

  @override
  String get setPrinterNotConfigured =>
      'Not configured. ESC/POS over LAN (port 9100).';

  @override
  String get setBusinessNameOnReceipts => 'Business name on receipts';

  @override
  String get setBusinessName => 'Business name';

  @override
  String get setReceiptFooter => 'Receipt footer';

  @override
  String get setPrintQueue => 'Print queue';

  @override
  String get setTables => 'Tables';

  @override
  String get setTableButton => 'Table';

  @override
  String get setAddTablesHint => 'Add tables to enable dine-in orders.';

  @override
  String get setInactive => 'Inactive';

  @override
  String get setRate => 'Rate';

  @override
  String get setTestPageSent => 'Test page sent to the printer.';

  @override
  String setTestPrintFailed(String message) {
    return 'Test print failed: $message';
  }

  @override
  String get setPrinterIp => 'Printer IP address';

  @override
  String get setPrinterIpHelper => 'Leave empty to disable printing.';

  @override
  String get setPort => 'Port';

  @override
  String get setPaper58 => '58mm paper';

  @override
  String get setPaper80 => '80mm paper';

  @override
  String get setNewTable => 'New table';

  @override
  String get setEditTable => 'Edit table';

  @override
  String get setTableLabelHint => 'Label (e.g. 1, 2, Patio A)';

  @override
  String get setActive => 'Active';

  @override
  String get setJobKitchenTicket => 'Kitchen ticket';

  @override
  String get setJobCustomerReceipt => 'Customer receipt';

  @override
  String get setJobTestPage => 'Test page';

  @override
  String get setJobQueued => 'Queued';

  @override
  String get setJobPrinting => 'Printing…';

  @override
  String get setJobPrinted => 'Printed';

  @override
  String get setJobFailed => 'Failed';

  @override
  String setJobStatusError(String status, String error) {
    return '$status — $error';
  }

  @override
  String get setRetry => 'Retry';

  @override
  String get setDiscard => 'Discard';

  @override
  String get setCloudSync => 'Cloud sync';

  @override
  String get setCloudBackingUp => 'Backing up to your Supabase';

  @override
  String get setCloudNotConfigured => 'Not configured';

  @override
  String setCloudConfiguredSubtitle(String url) {
    return '$url\nOptional — the POS works fully offline.';
  }

  @override
  String get setCloudNotConfiguredSubtitle =>
      'Back up and sync to your own Supabase project. Optional; the POS works fully offline without it.';

  @override
  String get setSetUp => 'Set up';

  @override
  String setSignedInAs(String email) {
    return 'Signed in as $email';
  }

  @override
  String get setSignInRequired => 'Restaurant sign-in required';

  @override
  String get setSignedInSubtitle =>
      'Sync and online orders use this secure login.';

  @override
  String get setSignInRequiredSubtitle =>
      'Cloud features need your restaurant Supabase login so your data stays private. (Customers never get it.)';

  @override
  String get setSignOut => 'Sign out';

  @override
  String get setSignIn => 'Sign in';

  @override
  String setLastSynced(String time) {
    return 'Last synced $time';
  }

  @override
  String get setSyncNow => 'Sync now';

  @override
  String get setRestoreFromCloud => 'Restore from cloud';

  @override
  String get setRestaurantSignIn => 'Restaurant sign-in';

  @override
  String get setSignInBody =>
      'Sign in with the Supabase user you created for this restaurant. This keeps your data private from customers.';

  @override
  String get setEmail => 'Email';

  @override
  String get setPassword => 'Password';

  @override
  String get setSignedInMsg => 'Signed in.';

  @override
  String setSignInFailed(String error) {
    return 'Sign-in failed: $error';
  }

  @override
  String get setSignedOutMsg => 'Signed out.';

  @override
  String setSyncedMsg(int pulled, int pushed) {
    return 'Synced: $pulled in, $pushed out.';
  }

  @override
  String setSyncFailed(String error) {
    return 'Sync failed: $error';
  }

  @override
  String get setRestoreTitle => 'Restore from cloud?';

  @override
  String get setRestoreBody =>
      'Pulls the full history from your Supabase and applies it to this device. Use this on a new or wiped tablet. Existing local data is merged (last write wins), never wiped.';

  @override
  String get setRestore => 'Restore';

  @override
  String setRestoredMsg(int pulled) {
    return 'Restored $pulled changes from the cloud.';
  }

  @override
  String setRestoreFailed(String error) {
    return 'Restore failed: $error';
  }

  @override
  String get setYourSupabaseProject => 'Your Supabase project';

  @override
  String get setSupabaseBody =>
      'Enter your project URL and anon (public) key. Create a \"sync_changes\" table first — see the setup SQL in the docs. Leave the URL empty to turn sync off.';

  @override
  String get setProjectUrl => 'Project URL';

  @override
  String get setAnonKey => 'Anon key';
}
