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
  String get commonApply => 'Apply';

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
  String ordServiceFeePercent(String rate) {
    return 'Service fee ($rate%)';
  }

  @override
  String get ordDiscount => 'Discount';

  @override
  String get ordDiscountPercent => 'Discount percent';

  @override
  String get ordAddDiscount => 'Add discount';

  @override
  String get ordEditDiscount => 'Edit discount';

  @override
  String get ordRemoveDiscount => 'Remove';

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
  String get menuLoadSample => 'Load sample menu';

  @override
  String get menuLoadSampleConfirm =>
      'Add the Yee Sushi sample menu (7 categories, 29 bilingual items) to try out ordering and printing? Re-loading just refreshes the same items.';

  @override
  String get menuLoadSampleDone => 'Sample menu loaded.';

  @override
  String get menuNewItem => 'New item';

  @override
  String get menuEditItem => 'Edit item';

  @override
  String get menuPrice => 'Price';

  @override
  String get menuDeleteItem => 'Delete item';

  @override
  String menuDeleteItemConfirm(String name) {
    return 'Delete \"$name\"? This can\'t be undone.';
  }

  @override
  String get menuDeleteCategory => 'Delete category';

  @override
  String menuDeleteCategoryConfirm(String name, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Delete \"$name\" and its $count items? This can\'t be undone.',
      one: 'Delete \"$name\" and its 1 item? This can\'t be undone.',
      zero: 'Delete \"$name\"? This can\'t be undone.',
    );
    return '$_temp0';
  }

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
  String get inboxProposeTime => 'Propose time';

  @override
  String get inboxTimeProposed =>
      'New time proposed — waiting for the customer.';

  @override
  String get inboxAwaitingApproval => 'Awaiting customer approval';

  @override
  String get inboxNoneAwaiting => 'No orders awaiting customer approval.';

  @override
  String inboxProposedWaiting(String time) {
    return 'Proposed $time — waiting for the customer to approve.';
  }

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
  String get setCheckout => 'Checkout';

  @override
  String get setServiceFee => 'Service fee';

  @override
  String get setServiceFeeHint => 'Charged on every order. 0% for none.';

  @override
  String get setDiscountPresets => 'Discount presets';

  @override
  String get setDiscountPresetsNone => 'None set';

  @override
  String get setDiscountPresetsHint =>
      'Comma-separated percentages, e.g. 5, 10, 15';

  @override
  String get setDiscountThreshold => 'Discount without manager';

  @override
  String get setDiscountThresholdHint => 'Larger discounts need a manager PIN.';

  @override
  String get setOnlineOrdering => 'Online ordering';

  @override
  String get setPickupLead => 'Minimum pickup time';

  @override
  String get setPickupLeadSubtitle =>
      'Soonest a customer can ask to pick up. Sent with the menu.';

  @override
  String setPickupLeadValue(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes min',
      one: '1 min',
      zero: 'No minimum',
    );
    return '$_temp0';
  }

  @override
  String get setNewOrderSound => 'Alert sound on new order';

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
  String get setPrinterSearch => 'Search for printers';

  @override
  String get setPrinterSearching => 'Searching the network…';

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
  String get setCustomerQr => 'Customer connect code';

  @override
  String get setCustomerQrTitle => 'Scan to order';

  @override
  String get setCustomerQrHint =>
      'Customers scan this with the ordering app to add your restaurant and preorder for pickup.';

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

  @override
  String get navAdmin => 'Admin';

  @override
  String get roleOwner => 'Owner';

  @override
  String get roleManager => 'Manager';

  @override
  String get roleServer => 'Server';

  @override
  String get roleSignIn => 'Sign in';

  @override
  String get roleSwitchUser => 'Switch user';

  @override
  String get roleSignOut => 'Sign out';

  @override
  String get roleNoStaffYet => 'No staff set up yet';

  @override
  String get roleAccessRequired => 'Manager access required';

  @override
  String get pinEnterTitle => 'Sign in';

  @override
  String get pinNameLabel => 'Name';

  @override
  String get pinFieldLabel => '4-digit PIN';

  @override
  String get pinIncorrect => 'Incorrect name or PIN';

  @override
  String get pinUnlock => 'Unlock';

  @override
  String get adminStaffSection => 'Staff & roles';

  @override
  String get adminAddStaff => 'Add staff';

  @override
  String get adminManageStaffOwnerOnly => 'Only an owner can manage staff.';

  @override
  String get adminNewStaff => 'New staff';

  @override
  String get adminEditStaff => 'Edit staff';

  @override
  String get adminStaffName => 'Name';

  @override
  String get adminStaffRole => 'Role';

  @override
  String get adminStaffNameRequired => 'Enter a name.';

  @override
  String get adminStaffPinRequired => 'Set a 4-digit PIN.';

  @override
  String get adminStaffPinKeepHint => 'Leave blank to keep the current PIN.';

  @override
  String get adminCannotDeleteLastOwner => 'Can\'t remove the last owner.';

  @override
  String adminRemoveStaffConfirm(String name) {
    return 'Remove $name?';
  }

  @override
  String get adminBootstrapTitle => 'Set up staff access';

  @override
  String get adminBootstrapBody =>
      'Create the first owner account to turn on role-based access. Until then, everyone has full access.';

  @override
  String get adminCreateFirstOwner => 'Create the first owner';

  @override
  String get adminManagementSection => 'Management';

  @override
  String get adminComingSoon => 'Coming soon';

  @override
  String get adminOnlineAuth => 'Online authorizations';

  @override
  String get adminOnlineAuthBody =>
      'When connected to your backend, high-risk actions can require a one-time passcode sent to the owner.';

  @override
  String get adminDiscounts => 'Discounts & comps';

  @override
  String get adminEndOfDay => 'End-of-day cash count';

  @override
  String get adminExport => 'Export data';

  @override
  String get itemCodeLabel => 'Item code (optional)';

  @override
  String get itemNameSecondaryLabel => 'Second name (optional)';

  @override
  String get itemDescriptionLabel => 'Description (optional)';

  @override
  String get itemFieldsSection => 'Custom fields';

  @override
  String get itemFieldLabelHint => 'Field';

  @override
  String get itemFieldValueHint => 'Value';

  @override
  String get itemAddField => 'Add field';

  @override
  String get itemFieldCustom => 'Custom…';

  @override
  String get fieldPresetDescription => 'Description';

  @override
  String get fieldPresetIngredients => 'Ingredients';

  @override
  String get fieldPresetAllergens => 'Allergens';

  @override
  String get fieldPresetSpice => 'Spice level';

  @override
  String get fieldPresetNotes => 'Notes';

  @override
  String get itemImagesSection => 'Photos';

  @override
  String get itemAddImage => 'Add photo';

  @override
  String get itemImageLabelHint => 'Label';

  @override
  String get itemSaveFirstForPhotos => 'Save the item first to add photos.';

  @override
  String get itemRenameImage => 'Rename photo';

  @override
  String get captureImportFromPhoto => 'Import from photo';

  @override
  String get captureTemplatesTitle => 'Capture templates';

  @override
  String get captureNewTemplate => 'New template';

  @override
  String get captureNoTemplates =>
      'No templates yet. Create one to map where each field sits on a menu photo.';

  @override
  String get captureTemplateNameHint => 'Template name';

  @override
  String get captureRenameTemplate => 'Rename template';

  @override
  String get captureDeleteTemplate => 'Delete template';

  @override
  String captureDeleteTemplateConfirm(String name) {
    return 'Delete template \"$name\"?';
  }

  @override
  String get captureTemplateEditorTitle => 'Template';

  @override
  String get capturePickSamplePhoto => 'Pick a sample photo';

  @override
  String get captureBigBlockHint =>
      'Drag the large box over one item, then add labeled regions inside it.';

  @override
  String get captureAddRegion => 'Add region';

  @override
  String get captureRegionField => 'Field';

  @override
  String get captureRegionLabel => 'Label';

  @override
  String get captureDeleteRegion => 'Delete region';

  @override
  String get captureSaveTemplate => 'Save template';

  @override
  String get captureTemplateNameRequired => 'Name the template.';

  @override
  String get captureNeedsBlockAndRegion =>
      'Draw the big box and at least one region.';

  @override
  String get captureFieldCode => 'Code';

  @override
  String get captureFieldName => 'Name';

  @override
  String get captureFieldNameSecondary => 'Second name';

  @override
  String get captureFieldPrice => 'Price';

  @override
  String get captureFieldAttribute => 'Custom field';

  @override
  String get captureFieldImage => 'Photo';

  @override
  String get captureTitle => 'Import from photo';

  @override
  String get capturePickPhoto => 'Pick menu photo';

  @override
  String get captureChooseTemplate => 'Template';

  @override
  String get captureChooseCategory => 'Category';

  @override
  String get captureRunningOcr => 'Reading text…';

  @override
  String get captureCaptureItem => 'Capture item';

  @override
  String captureDraftCount(int count) {
    return '$count captured';
  }

  @override
  String get captureReviewAction => 'Review';

  @override
  String get captureOcrLanguageMissing =>
      'No OCR language pack found. Add Chinese or English in Windows Settings → Time & language → Language.';

  @override
  String get captureSelectTemplateFirst => 'Choose a template first.';

  @override
  String get captureSelectPhotoFirst => 'Choose a photo first.';

  @override
  String get captureReviewTitle => 'Review drafts';

  @override
  String get captureSaveAll => 'Save all';

  @override
  String get captureDiscardDraft => 'Discard';

  @override
  String get captureNoDrafts => 'Nothing captured yet.';

  @override
  String captureSavedCount(int count) {
    return 'Saved $count items';
  }

  @override
  String get captureUnsupportedPlatform =>
      'Photo import runs on Windows for now.';

  @override
  String get captureTemplatesShort => 'Templates';

  @override
  String get captureLabelsToggle => 'Labels';

  @override
  String get captureCreateTemplate => 'Create a template';

  @override
  String get captureResetRegions => 'Reset layout';

  @override
  String get setSecondNameSection => 'Second name display';

  @override
  String get setSecondNameHint =>
      'Where the optional second (e.g. native-language) name appears.';

  @override
  String get setSecondNameOrderScreen => 'On order screen';

  @override
  String get setSecondNameKitchen => 'On kitchen ticket';

  @override
  String get setSecondNameReceipt => 'On customer receipt';

  @override
  String get setSecondNameLanguage => 'Second name language';

  @override
  String get setSecondNameLanguageHint =>
      'Customers see this name first when their app is in this language.';

  @override
  String get setSecondNameLanguageNone => 'Not set';
}
