import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
  ];

  /// Application title shown in the OS task switcher
  ///
  /// In en, this message translates to:
  /// **'Restaurant System'**
  String get appTitle;

  /// No description provided for @navOrders.
  ///
  /// In en, this message translates to:
  /// **'Orders'**
  String get navOrders;

  /// No description provided for @navMenu.
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get navMenu;

  /// No description provided for @navInbox.
  ///
  /// In en, this message translates to:
  /// **'Inbox'**
  String get navInbox;

  /// No description provided for @navReports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get navReports;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonApply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get commonApply;

  /// No description provided for @commonSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// No description provided for @commonDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get commonDelete;

  /// No description provided for @commonAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get commonAdd;

  /// No description provided for @commonEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get commonEdit;

  /// No description provided for @commonClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get commonClose;

  /// No description provided for @commonRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get commonRemove;

  /// No description provided for @commonDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get commonDone;

  /// No description provided for @orderDineIn.
  ///
  /// In en, this message translates to:
  /// **'Dine-in'**
  String get orderDineIn;

  /// No description provided for @orderTakeout.
  ///
  /// In en, this message translates to:
  /// **'Takeout'**
  String get orderTakeout;

  /// No description provided for @orderOnline.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get orderOnline;

  /// No description provided for @orderTableLabel.
  ///
  /// In en, this message translates to:
  /// **'Table {label}'**
  String orderTableLabel(String label);

  /// No description provided for @payCash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get payCash;

  /// No description provided for @payCard.
  ///
  /// In en, this message translates to:
  /// **'Card'**
  String get payCard;

  /// No description provided for @payCardKeyed.
  ///
  /// In en, this message translates to:
  /// **'Card (keyed)'**
  String get payCardKeyed;

  /// No description provided for @ordersTitle.
  ///
  /// In en, this message translates to:
  /// **'Open Orders'**
  String get ordersTitle;

  /// No description provided for @ordersEmpty.
  ///
  /// In en, this message translates to:
  /// **'No open orders — start a dine-in or takeout order.'**
  String get ordersEmpty;

  /// No description provided for @ordersLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load orders: {error}'**
  String ordersLoadFailed(String error);

  /// No description provided for @noTablesYet.
  ///
  /// In en, this message translates to:
  /// **'No tables yet — add tables in Settings.'**
  String get noTablesYet;

  /// No description provided for @pickTable.
  ///
  /// In en, this message translates to:
  /// **'Pick a table'**
  String get pickTable;

  /// No description provided for @ordVoidOrder.
  ///
  /// In en, this message translates to:
  /// **'Void order'**
  String get ordVoidOrder;

  /// No description provided for @ordDineInTitle.
  ///
  /// In en, this message translates to:
  /// **'Dine-in order'**
  String get ordDineInTitle;

  /// No description provided for @ordTakeoutTitle.
  ///
  /// In en, this message translates to:
  /// **'Takeout order'**
  String get ordTakeoutTitle;

  /// No description provided for @ordOnlineTitle.
  ///
  /// In en, this message translates to:
  /// **'Online order'**
  String get ordOnlineTitle;

  /// No description provided for @ordOrderTitle.
  ///
  /// In en, this message translates to:
  /// **'Order'**
  String get ordOrderTitle;

  /// No description provided for @ordVoidConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Void this order?'**
  String get ordVoidConfirmTitle;

  /// No description provided for @ordVoidConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'The order is kept in history as voided.'**
  String get ordVoidConfirmBody;

  /// No description provided for @ordKeep.
  ///
  /// In en, this message translates to:
  /// **'Keep'**
  String get ordKeep;

  /// No description provided for @ordNoMenuYet.
  ///
  /// In en, this message translates to:
  /// **'No menu yet — add categories and items in Menu.'**
  String get ordNoMenuYet;

  /// No description provided for @ordTapToAdd.
  ///
  /// In en, this message translates to:
  /// **'Tap menu items to add them.'**
  String get ordTapToAdd;

  /// No description provided for @ordVoidLine.
  ///
  /// In en, this message translates to:
  /// **'Void line'**
  String get ordVoidLine;

  /// No description provided for @ordDecrease.
  ///
  /// In en, this message translates to:
  /// **'Decrease'**
  String get ordDecrease;

  /// No description provided for @ordQtyMultiplier.
  ///
  /// In en, this message translates to:
  /// **'x{qty}'**
  String ordQtyMultiplier(int qty);

  /// No description provided for @ordSubtotal.
  ///
  /// In en, this message translates to:
  /// **'Subtotal'**
  String get ordSubtotal;

  /// No description provided for @ordTaxPercent.
  ///
  /// In en, this message translates to:
  /// **'Tax ({rate}%)'**
  String ordTaxPercent(String rate);

  /// No description provided for @ordServiceFeePercent.
  ///
  /// In en, this message translates to:
  /// **'Service fee ({rate}%)'**
  String ordServiceFeePercent(String rate);

  /// No description provided for @ordDiscount.
  ///
  /// In en, this message translates to:
  /// **'Discount'**
  String get ordDiscount;

  /// No description provided for @ordDiscountPercent.
  ///
  /// In en, this message translates to:
  /// **'Discount percent'**
  String get ordDiscountPercent;

  /// No description provided for @ordAddDiscount.
  ///
  /// In en, this message translates to:
  /// **'Add discount'**
  String get ordAddDiscount;

  /// No description provided for @ordEditDiscount.
  ///
  /// In en, this message translates to:
  /// **'Edit discount'**
  String get ordEditDiscount;

  /// No description provided for @ordCategoryLayout.
  ///
  /// In en, this message translates to:
  /// **'Category layout'**
  String get ordCategoryLayout;

  /// No description provided for @ordRemoveDiscount.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get ordRemoveDiscount;

  /// No description provided for @ordTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get ordTotal;

  /// No description provided for @ordPaidMethod.
  ///
  /// In en, this message translates to:
  /// **'Paid — {method}'**
  String ordPaidMethod(String method);

  /// No description provided for @ordTipSuffix.
  ///
  /// In en, this message translates to:
  /// **' (tip {tip})'**
  String ordTipSuffix(String tip);

  /// No description provided for @ordBalanceDue.
  ///
  /// In en, this message translates to:
  /// **'Balance due'**
  String get ordBalanceDue;

  /// No description provided for @ordReprintKitchenTicket.
  ///
  /// In en, this message translates to:
  /// **'Reprint kitchen ticket'**
  String get ordReprintKitchenTicket;

  /// No description provided for @ordSendToKitchen.
  ///
  /// In en, this message translates to:
  /// **'Send to kitchen'**
  String get ordSendToKitchen;

  /// No description provided for @ordPayAmount.
  ///
  /// In en, this message translates to:
  /// **'Pay {amount}'**
  String ordPayAmount(String amount);

  /// No description provided for @ordClosed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get ordClosed;

  /// No description provided for @ordNoPrinterConfigured.
  ///
  /// In en, this message translates to:
  /// **'No printer configured — set one up in Settings.'**
  String get ordNoPrinterConfigured;

  /// No description provided for @ordKitchenTicketQueued.
  ///
  /// In en, this message translates to:
  /// **'Kitchen ticket queued.'**
  String get ordKitchenTicketQueued;

  /// No description provided for @ordPartialPaymentRecorded.
  ///
  /// In en, this message translates to:
  /// **'Partial payment recorded — order stays open.'**
  String get ordPartialPaymentRecorded;

  /// No description provided for @ordCardDeclined.
  ///
  /// In en, this message translates to:
  /// **'Card declined — not recorded as paid.'**
  String get ordCardDeclined;

  /// No description provided for @ordPaymentFailed.
  ///
  /// In en, this message translates to:
  /// **'Payment failed: {message}'**
  String ordPaymentFailed(String message);

  /// No description provided for @menuTitle.
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get menuTitle;

  /// No description provided for @menuItems.
  ///
  /// In en, this message translates to:
  /// **'Items'**
  String get menuItems;

  /// No description provided for @menuModifierGroups.
  ///
  /// In en, this message translates to:
  /// **'Modifier groups'**
  String get menuModifierGroups;

  /// No description provided for @menuHiddenFromOrderScreen.
  ///
  /// In en, this message translates to:
  /// **'Hidden from order screen'**
  String get menuHiddenFromOrderScreen;

  /// No description provided for @menuCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get menuCategory;

  /// No description provided for @menuCreateCategoryToStart.
  ///
  /// In en, this message translates to:
  /// **'Create a category to start your menu.'**
  String get menuCreateCategoryToStart;

  /// No description provided for @menuNewCategory.
  ///
  /// In en, this message translates to:
  /// **'New category'**
  String get menuNewCategory;

  /// No description provided for @menuEditCategory.
  ///
  /// In en, this message translates to:
  /// **'Edit category'**
  String get menuEditCategory;

  /// No description provided for @menuName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get menuName;

  /// No description provided for @menuVisibleOnOrderScreen.
  ///
  /// In en, this message translates to:
  /// **'Visible on order screen'**
  String get menuVisibleOnOrderScreen;

  /// No description provided for @menuItem.
  ///
  /// In en, this message translates to:
  /// **'Item'**
  String get menuItem;

  /// No description provided for @menuNoItemsInCategory.
  ///
  /// In en, this message translates to:
  /// **'No items in this category yet.'**
  String get menuNoItemsInCategory;

  /// No description provided for @menuLoadSample.
  ///
  /// In en, this message translates to:
  /// **'Load sample menu'**
  String get menuLoadSample;

  /// No description provided for @menuLoadSampleConfirm.
  ///
  /// In en, this message translates to:
  /// **'Add the Yee Sushi sample menu (7 categories, 29 bilingual items) to try out ordering and printing? Re-loading just refreshes the same items.'**
  String get menuLoadSampleConfirm;

  /// No description provided for @menuLoadSampleDone.
  ///
  /// In en, this message translates to:
  /// **'Sample menu loaded.'**
  String get menuLoadSampleDone;

  /// No description provided for @menuNewItem.
  ///
  /// In en, this message translates to:
  /// **'New item'**
  String get menuNewItem;

  /// No description provided for @menuEditItem.
  ///
  /// In en, this message translates to:
  /// **'Edit item'**
  String get menuEditItem;

  /// No description provided for @menuPrice.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get menuPrice;

  /// No description provided for @menuDeleteItem.
  ///
  /// In en, this message translates to:
  /// **'Delete item'**
  String get menuDeleteItem;

  /// No description provided for @menuDeleteItemConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{name}\"? This can\'t be undone.'**
  String menuDeleteItemConfirm(String name);

  /// No description provided for @menuDeleteCategory.
  ///
  /// In en, this message translates to:
  /// **'Delete category'**
  String get menuDeleteCategory;

  /// No description provided for @menuDeleteCategoryConfirm.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Delete \"{name}\"? This can\'t be undone.} =1{Delete \"{name}\" and its 1 item? This can\'t be undone.} other{Delete \"{name}\" and its {count} items? This can\'t be undone.}}'**
  String menuDeleteCategoryConfirm(String name, int count);

  /// No description provided for @modGroup.
  ///
  /// In en, this message translates to:
  /// **'Group'**
  String get modGroup;

  /// No description provided for @modGroupsEmpty.
  ///
  /// In en, this message translates to:
  /// **'Modifier groups (e.g. \"Size\", \"Add-ons\") appear here.'**
  String get modGroupsEmpty;

  /// No description provided for @modModifier.
  ///
  /// In en, this message translates to:
  /// **'Modifier'**
  String get modModifier;

  /// No description provided for @modEditGroup.
  ///
  /// In en, this message translates to:
  /// **'Edit group'**
  String get modEditGroup;

  /// No description provided for @modDeleteGroup.
  ///
  /// In en, this message translates to:
  /// **'Delete group'**
  String get modDeleteGroup;

  /// No description provided for @modOptionalPickOne.
  ///
  /// In en, this message translates to:
  /// **'Optional, pick one'**
  String get modOptionalPickOne;

  /// No description provided for @modOptionalUpTo.
  ///
  /// In en, this message translates to:
  /// **'Optional, up to {n}'**
  String modOptionalUpTo(int n);

  /// No description provided for @modRequiredPick.
  ///
  /// In en, this message translates to:
  /// **'Required, pick {n}'**
  String modRequiredPick(int n);

  /// No description provided for @modRequiredPickRange.
  ///
  /// In en, this message translates to:
  /// **'Required, pick {min}-{max}'**
  String modRequiredPickRange(int min, int max);

  /// No description provided for @modNewGroup.
  ///
  /// In en, this message translates to:
  /// **'New modifier group'**
  String get modNewGroup;

  /// No description provided for @modGroupNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name (e.g. Size, Add-ons)'**
  String get modGroupNameLabel;

  /// No description provided for @modMinPicks.
  ///
  /// In en, this message translates to:
  /// **'Min picks'**
  String get modMinPicks;

  /// No description provided for @modMaxPicks.
  ///
  /// In en, this message translates to:
  /// **'Max picks'**
  String get modMaxPicks;

  /// No description provided for @modNewModifier.
  ///
  /// In en, this message translates to:
  /// **'New modifier'**
  String get modNewModifier;

  /// No description provided for @modEditModifier.
  ///
  /// In en, this message translates to:
  /// **'Edit modifier'**
  String get modEditModifier;

  /// No description provided for @modName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get modName;

  /// No description provided for @modPriceChange.
  ///
  /// In en, this message translates to:
  /// **'Price change'**
  String get modPriceChange;

  /// No description provided for @modPriceChangeHelper.
  ///
  /// In en, this message translates to:
  /// **'Can be negative, e.g. -0.50'**
  String get modPriceChangeHelper;

  /// No description provided for @modDeleteGroupConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{name}\"?'**
  String modDeleteGroupConfirm(String name);

  /// No description provided for @modDeleteGroupBody.
  ///
  /// In en, this message translates to:
  /// **'Items lose this group. Past orders are unaffected (they keep snapshots).'**
  String get modDeleteGroupBody;

  /// No description provided for @modAddToOrder.
  ///
  /// In en, this message translates to:
  /// **'Add to order'**
  String get modAddToOrder;

  /// No description provided for @modOptional.
  ///
  /// In en, this message translates to:
  /// **'optional'**
  String get modOptional;

  /// No description provided for @modUpTo.
  ///
  /// In en, this message translates to:
  /// **'up to {n}'**
  String modUpTo(int n);

  /// No description provided for @modPick.
  ///
  /// In en, this message translates to:
  /// **'pick {n}'**
  String modPick(int n);

  /// No description provided for @modPickRange.
  ///
  /// In en, this message translates to:
  /// **'pick {min}-{max}'**
  String modPickRange(int min, int max);

  /// No description provided for @pmtAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get pmtAmount;

  /// No description provided for @pmtTipOptional.
  ///
  /// In en, this message translates to:
  /// **'Tip (optional)'**
  String get pmtTipOptional;

  /// No description provided for @pmtTipFromTerminal.
  ///
  /// In en, this message translates to:
  /// **'Tip from terminal (optional)'**
  String get pmtTipFromTerminal;

  /// No description provided for @pmtEnterValidAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid amount.'**
  String get pmtEnterValidAmount;

  /// No description provided for @pmtEnterValidTip.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid tip.'**
  String get pmtEnterValidTip;

  /// No description provided for @pmtAmountExceedsBalance.
  ///
  /// In en, this message translates to:
  /// **'Amount exceeds the balance ({balance}).'**
  String pmtAmountExceedsBalance(String balance);

  /// No description provided for @pmtCollect.
  ///
  /// In en, this message translates to:
  /// **'Collect {amount}'**
  String pmtCollect(String amount);

  /// No description provided for @pmtKeyAmountOnTerminal.
  ///
  /// In en, this message translates to:
  /// **'Key {amount} on the terminal'**
  String pmtKeyAmountOnTerminal(String amount);

  /// No description provided for @pmtKeyOnTerminalBody.
  ///
  /// In en, this message translates to:
  /// **'Enter the amount on the card terminal, then record the outcome shown on its screen.'**
  String get pmtKeyOnTerminalBody;

  /// No description provided for @pmtPartialPaymentHint.
  ///
  /// In en, this message translates to:
  /// **'Partial payment — the order stays open.'**
  String get pmtPartialPaymentHint;

  /// No description provided for @pmtLowerToSplitHint.
  ///
  /// In en, this message translates to:
  /// **'Lower the amount to split the bill.'**
  String get pmtLowerToSplitHint;

  /// No description provided for @pmtDeclined.
  ///
  /// In en, this message translates to:
  /// **'Declined'**
  String get pmtDeclined;

  /// No description provided for @pmtApproved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get pmtApproved;

  /// No description provided for @pmtCashTendered.
  ///
  /// In en, this message translates to:
  /// **'Cash tendered (optional)'**
  String get pmtCashTendered;

  /// No description provided for @pmtChangeDue.
  ///
  /// In en, this message translates to:
  /// **'Change due {amount}'**
  String pmtChangeDue(String amount);

  /// No description provided for @pmtPayingForItems.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Paying for 1 selected item} other{Paying for {count} selected items}}'**
  String pmtPayingForItems(int count);

  /// No description provided for @ordSplitByItem.
  ///
  /// In en, this message translates to:
  /// **'Split by item'**
  String get ordSplitByItem;

  /// No description provided for @splitTitle.
  ///
  /// In en, this message translates to:
  /// **'Split by item'**
  String get splitTitle;

  /// No description provided for @splitHint.
  ///
  /// In en, this message translates to:
  /// **'Tick the items for this person, then charge. Repeat until everything is paid.'**
  String get splitHint;

  /// No description provided for @splitAllPaid.
  ///
  /// In en, this message translates to:
  /// **'Every item is paid.'**
  String get splitAllPaid;

  /// No description provided for @splitPaid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get splitPaid;

  /// No description provided for @splitChargeSelected.
  ///
  /// In en, this message translates to:
  /// **'Charge selected — {amount}'**
  String splitChargeSelected(String amount);

  /// No description provided for @inboxTitle.
  ///
  /// In en, this message translates to:
  /// **'Online orders'**
  String get inboxTitle;

  /// No description provided for @inboxPublishMenu.
  ///
  /// In en, this message translates to:
  /// **'Publish menu'**
  String get inboxPublishMenu;

  /// No description provided for @inboxDisabledHint.
  ///
  /// In en, this message translates to:
  /// **'Set up your Supabase project in Settings to accept online preorders. The POS works fully without it.'**
  String get inboxDisabledHint;

  /// No description provided for @inboxNewPreorders.
  ///
  /// In en, this message translates to:
  /// **'New preorders'**
  String get inboxNewPreorders;

  /// No description provided for @inboxNoNewPreorders.
  ///
  /// In en, this message translates to:
  /// **'No new preorders.'**
  String get inboxNoNewPreorders;

  /// No description provided for @inboxPreparing.
  ///
  /// In en, this message translates to:
  /// **'Preparing'**
  String get inboxPreparing;

  /// No description provided for @inboxNothingInProgress.
  ///
  /// In en, this message translates to:
  /// **'Nothing in progress.'**
  String get inboxNothingInProgress;

  /// No description provided for @inboxMenuPublished.
  ///
  /// In en, this message translates to:
  /// **'Menu published to your storefront.'**
  String get inboxMenuPublished;

  /// No description provided for @inboxPublishFailed.
  ///
  /// In en, this message translates to:
  /// **'Publish failed: {error}'**
  String inboxPublishFailed(String error);

  /// No description provided for @inboxError.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String inboxError(String error);

  /// No description provided for @inboxCustomerPickup.
  ///
  /// In en, this message translates to:
  /// **'{name} — pickup {time}'**
  String inboxCustomerPickup(String name, String time);

  /// No description provided for @inboxTotalPayAtPickup.
  ///
  /// In en, this message translates to:
  /// **'Total {total} — pay at pickup'**
  String inboxTotalPayAtPickup(String total);

  /// No description provided for @inboxReject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get inboxReject;

  /// No description provided for @inboxAccept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get inboxAccept;

  /// No description provided for @inboxProposeTime.
  ///
  /// In en, this message translates to:
  /// **'Propose time'**
  String get inboxProposeTime;

  /// No description provided for @inboxTimeProposed.
  ///
  /// In en, this message translates to:
  /// **'New time proposed — waiting for the customer.'**
  String get inboxTimeProposed;

  /// No description provided for @inboxAwaitingApproval.
  ///
  /// In en, this message translates to:
  /// **'Awaiting customer approval'**
  String get inboxAwaitingApproval;

  /// No description provided for @inboxNoneAwaiting.
  ///
  /// In en, this message translates to:
  /// **'No orders awaiting customer approval.'**
  String get inboxNoneAwaiting;

  /// No description provided for @inboxProposedWaiting.
  ///
  /// In en, this message translates to:
  /// **'Proposed {time} — waiting for the customer to approve.'**
  String inboxProposedWaiting(String time);

  /// No description provided for @inboxReady.
  ///
  /// In en, this message translates to:
  /// **'Ready for pickup'**
  String get inboxReady;

  /// No description provided for @inboxNoneReady.
  ///
  /// In en, this message translates to:
  /// **'Nothing waiting for pickup.'**
  String get inboxNoneReady;

  /// No description provided for @inboxMarkPickedUp.
  ///
  /// In en, this message translates to:
  /// **'Mark picked up'**
  String get inboxMarkPickedUp;

  /// No description provided for @inboxMarkedPickedUp.
  ///
  /// In en, this message translates to:
  /// **'Order completed.'**
  String get inboxMarkedPickedUp;

  /// No description provided for @inboxAcceptedAdded.
  ///
  /// In en, this message translates to:
  /// **'Accepted — added to orders.'**
  String get inboxAcceptedAdded;

  /// No description provided for @inboxPreorderRejected.
  ///
  /// In en, this message translates to:
  /// **'Preorder rejected.'**
  String get inboxPreorderRejected;

  /// No description provided for @inboxCustomerNotifiedReady.
  ///
  /// In en, this message translates to:
  /// **'Customer notified: ready.'**
  String get inboxCustomerNotifiedReady;

  /// No description provided for @inboxMarkReady.
  ///
  /// In en, this message translates to:
  /// **'Mark ready'**
  String get inboxMarkReady;

  /// No description provided for @repTitle.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get repTitle;

  /// No description provided for @repPreviousDay.
  ///
  /// In en, this message translates to:
  /// **'Previous day'**
  String get repPreviousDay;

  /// No description provided for @repNextDay.
  ///
  /// In en, this message translates to:
  /// **'Next day'**
  String get repNextDay;

  /// No description provided for @repCollected.
  ///
  /// In en, this message translates to:
  /// **'Collected'**
  String get repCollected;

  /// No description provided for @repItemSales.
  ///
  /// In en, this message translates to:
  /// **'Item sales'**
  String get repItemSales;

  /// No description provided for @repItemQty.
  ///
  /// In en, this message translates to:
  /// **'{qty}x'**
  String repItemQty(int qty);

  /// No description provided for @repOrderHistory.
  ///
  /// In en, this message translates to:
  /// **'Order history'**
  String get repOrderHistory;

  /// No description provided for @repNoClosedOrders.
  ///
  /// In en, this message translates to:
  /// **'No closed orders on this day.'**
  String get repNoClosedOrders;

  /// No description provided for @repOrders.
  ///
  /// In en, this message translates to:
  /// **'Orders'**
  String get repOrders;

  /// No description provided for @repOrdersVoided.
  ///
  /// In en, this message translates to:
  /// **'{count} voided'**
  String repOrdersVoided(int count);

  /// No description provided for @repGrossSales.
  ///
  /// In en, this message translates to:
  /// **'Gross sales'**
  String get repGrossSales;

  /// No description provided for @repSubtotalValue.
  ///
  /// In en, this message translates to:
  /// **'Subtotal {amount}'**
  String repSubtotalValue(String amount);

  /// No description provided for @repTax.
  ///
  /// In en, this message translates to:
  /// **'Tax'**
  String get repTax;

  /// No description provided for @repTips.
  ///
  /// In en, this message translates to:
  /// **'Tips'**
  String get repTips;

  /// No description provided for @repPaymentsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} payments'**
  String repPaymentsCount(int count);

  /// No description provided for @repPaymentsCountTips.
  ///
  /// In en, this message translates to:
  /// **'{count} payments — tips {tips}'**
  String repPaymentsCountTips(int count, String tips);

  /// No description provided for @repTotalCollected.
  ///
  /// In en, this message translates to:
  /// **'Total collected'**
  String get repTotalCollected;

  /// No description provided for @repOrderVoidedSuffix.
  ///
  /// In en, this message translates to:
  /// **'{ref} — voided'**
  String repOrderVoidedSuffix(String ref);

  /// No description provided for @repOrderVoidedParen.
  ///
  /// In en, this message translates to:
  /// **'{ref} (voided)'**
  String repOrderVoidedParen(String ref);

  /// No description provided for @repLineQtyName.
  ///
  /// In en, this message translates to:
  /// **'{qty} x {name}'**
  String repLineQtyName(int qty, String name);

  /// No description provided for @repTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get repTotal;

  /// No description provided for @repTipValue.
  ///
  /// In en, this message translates to:
  /// **'Tip {amount}'**
  String repTipValue(String amount);

  /// No description provided for @repReceiptQueued.
  ///
  /// In en, this message translates to:
  /// **'Receipt queued.'**
  String get repReceiptQueued;

  /// No description provided for @repReprintReceipt.
  ///
  /// In en, this message translates to:
  /// **'Reprint receipt'**
  String get repReprintReceipt;

  /// No description provided for @setLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get setLanguage;

  /// No description provided for @setLanguageSystem.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get setLanguageSystem;

  /// No description provided for @setTax.
  ///
  /// In en, this message translates to:
  /// **'Tax'**
  String get setTax;

  /// No description provided for @setSalesTaxRate.
  ///
  /// In en, this message translates to:
  /// **'Sales tax rate'**
  String get setSalesTaxRate;

  /// No description provided for @setSalesTaxRateSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Applied to new orders; existing orders keep their rate.'**
  String get setSalesTaxRateSubtitle;

  /// No description provided for @setCheckout.
  ///
  /// In en, this message translates to:
  /// **'Checkout'**
  String get setCheckout;

  /// No description provided for @setServiceFee.
  ///
  /// In en, this message translates to:
  /// **'Service fee'**
  String get setServiceFee;

  /// No description provided for @setServiceFeeHint.
  ///
  /// In en, this message translates to:
  /// **'Charged on every order. 0% for none.'**
  String get setServiceFeeHint;

  /// No description provided for @setDiscountPresets.
  ///
  /// In en, this message translates to:
  /// **'Discount presets'**
  String get setDiscountPresets;

  /// No description provided for @setDiscountPresetsNone.
  ///
  /// In en, this message translates to:
  /// **'None set'**
  String get setDiscountPresetsNone;

  /// No description provided for @setDiscountPresetsHint.
  ///
  /// In en, this message translates to:
  /// **'Comma-separated percentages, e.g. 5, 10, 15'**
  String get setDiscountPresetsHint;

  /// No description provided for @setDiscountThreshold.
  ///
  /// In en, this message translates to:
  /// **'Discount without manager'**
  String get setDiscountThreshold;

  /// No description provided for @setDiscountThresholdHint.
  ///
  /// In en, this message translates to:
  /// **'Larger discounts need a manager PIN.'**
  String get setDiscountThresholdHint;

  /// No description provided for @setOnlineOrdering.
  ///
  /// In en, this message translates to:
  /// **'Online ordering'**
  String get setOnlineOrdering;

  /// No description provided for @setPickupLead.
  ///
  /// In en, this message translates to:
  /// **'Minimum pickup time'**
  String get setPickupLead;

  /// No description provided for @setPickupLeadSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Soonest a customer can ask to pick up. Sent with the menu.'**
  String get setPickupLeadSubtitle;

  /// No description provided for @setPickupLeadValue.
  ///
  /// In en, this message translates to:
  /// **'{minutes, plural, =0{No minimum} =1{1 min} other{{minutes} min}}'**
  String setPickupLeadValue(int minutes);

  /// No description provided for @setNewOrderSound.
  ///
  /// In en, this message translates to:
  /// **'Alert sound on new order'**
  String get setNewOrderSound;

  /// No description provided for @setPayments.
  ///
  /// In en, this message translates to:
  /// **'Payments'**
  String get setPayments;

  /// No description provided for @setCardTerminalManual.
  ///
  /// In en, this message translates to:
  /// **'Card terminal: manual entry'**
  String get setCardTerminalManual;

  /// No description provided for @setCardTerminalManualSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Staff key the amount on the standalone terminal and record the outcome. Semi-integrated Moneris Go support arrives once the Moneris Cloud API access is set up.'**
  String get setCardTerminalManualSubtitle;

  /// No description provided for @setPrinting.
  ///
  /// In en, this message translates to:
  /// **'Printing'**
  String get setPrinting;

  /// No description provided for @setTestPrint.
  ///
  /// In en, this message translates to:
  /// **'Test print'**
  String get setTestPrint;

  /// No description provided for @setNetworkPrinter.
  ///
  /// In en, this message translates to:
  /// **'Network printer'**
  String get setNetworkPrinter;

  /// No description provided for @setPrinterConfigured.
  ///
  /// In en, this message translates to:
  /// **'{host}:{port} — {width}mm paper'**
  String setPrinterConfigured(String host, int port, String width);

  /// No description provided for @setPrinterNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'Not configured.'**
  String get setPrinterNotConfigured;

  /// No description provided for @setPrinterConfiguredUsb.
  ///
  /// In en, this message translates to:
  /// **'{name} — {width}mm paper'**
  String setPrinterConfiguredUsb(String name, String width);

  /// No description provided for @setPrinterKitchen.
  ///
  /// In en, this message translates to:
  /// **'Kitchen printer'**
  String get setPrinterKitchen;

  /// No description provided for @setPrinterReceipt.
  ///
  /// In en, this message translates to:
  /// **'Receipt printer'**
  String get setPrinterReceipt;

  /// No description provided for @setTransportNetwork.
  ///
  /// In en, this message translates to:
  /// **'Network'**
  String get setTransportNetwork;

  /// No description provided for @setTransportWindows.
  ///
  /// In en, this message translates to:
  /// **'USB / Windows'**
  String get setTransportWindows;

  /// No description provided for @setWindowsPrinter.
  ///
  /// In en, this message translates to:
  /// **'Windows printer'**
  String get setWindowsPrinter;

  /// No description provided for @setWindowsPrinterNone.
  ///
  /// In en, this message translates to:
  /// **'No printers found. Install the printer in Windows first, then refresh.'**
  String get setWindowsPrinterNone;

  /// No description provided for @setRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get setRefresh;

  /// No description provided for @setPaperWidth.
  ///
  /// In en, this message translates to:
  /// **'Paper width'**
  String get setPaperWidth;

  /// No description provided for @setCharset.
  ///
  /// In en, this message translates to:
  /// **'Text encoding'**
  String get setCharset;

  /// No description provided for @setCharsetWestern.
  ///
  /// In en, this message translates to:
  /// **'Western'**
  String get setCharsetWestern;

  /// No description provided for @setCharsetChinese.
  ///
  /// In en, this message translates to:
  /// **'Chinese'**
  String get setCharsetChinese;

  /// No description provided for @setOpenDrawer.
  ///
  /// In en, this message translates to:
  /// **'Open cash drawer on receipt'**
  String get setOpenDrawer;

  /// No description provided for @setBusinessNameOnReceipts.
  ///
  /// In en, this message translates to:
  /// **'Business name on receipts'**
  String get setBusinessNameOnReceipts;

  /// No description provided for @setBusinessName.
  ///
  /// In en, this message translates to:
  /// **'Business name'**
  String get setBusinessName;

  /// No description provided for @setReceiptFooter.
  ///
  /// In en, this message translates to:
  /// **'Receipt footer'**
  String get setReceiptFooter;

  /// No description provided for @setCustomerDisplay.
  ///
  /// In en, this message translates to:
  /// **'Customer display (second screen)'**
  String get setCustomerDisplay;

  /// No description provided for @setOpenCustomerDisplay.
  ///
  /// In en, this message translates to:
  /// **'Open customer display'**
  String get setOpenCustomerDisplay;

  /// No description provided for @setCustomerDisplayHint.
  ///
  /// In en, this message translates to:
  /// **'Opens a window for the extended monitor; drag it to the customer-facing screen.'**
  String get setCustomerDisplayHint;

  /// No description provided for @setPrintQueue.
  ///
  /// In en, this message translates to:
  /// **'Print queue'**
  String get setPrintQueue;

  /// No description provided for @setTables.
  ///
  /// In en, this message translates to:
  /// **'Tables'**
  String get setTables;

  /// No description provided for @setTableButton.
  ///
  /// In en, this message translates to:
  /// **'Table'**
  String get setTableButton;

  /// No description provided for @setAddTablesHint.
  ///
  /// In en, this message translates to:
  /// **'Add tables to enable dine-in orders.'**
  String get setAddTablesHint;

  /// No description provided for @setInactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get setInactive;

  /// No description provided for @setRate.
  ///
  /// In en, this message translates to:
  /// **'Rate'**
  String get setRate;

  /// No description provided for @setTestPageSent.
  ///
  /// In en, this message translates to:
  /// **'Test page sent to the printer.'**
  String get setTestPageSent;

  /// No description provided for @setTestPrintFailed.
  ///
  /// In en, this message translates to:
  /// **'Test print failed: {message}'**
  String setTestPrintFailed(String message);

  /// No description provided for @setPrinterIp.
  ///
  /// In en, this message translates to:
  /// **'Printer IP address'**
  String get setPrinterIp;

  /// No description provided for @setPrinterIpHelper.
  ///
  /// In en, this message translates to:
  /// **'Leave empty to disable printing.'**
  String get setPrinterIpHelper;

  /// No description provided for @setPrinterSearch.
  ///
  /// In en, this message translates to:
  /// **'Search for printers'**
  String get setPrinterSearch;

  /// No description provided for @setPrinterSearching.
  ///
  /// In en, this message translates to:
  /// **'Searching the network…'**
  String get setPrinterSearching;

  /// No description provided for @setPort.
  ///
  /// In en, this message translates to:
  /// **'Port'**
  String get setPort;

  /// No description provided for @setPaper58.
  ///
  /// In en, this message translates to:
  /// **'58mm paper'**
  String get setPaper58;

  /// No description provided for @setPaper80.
  ///
  /// In en, this message translates to:
  /// **'80mm paper'**
  String get setPaper80;

  /// No description provided for @setNewTable.
  ///
  /// In en, this message translates to:
  /// **'New table'**
  String get setNewTable;

  /// No description provided for @setEditTable.
  ///
  /// In en, this message translates to:
  /// **'Edit table'**
  String get setEditTable;

  /// No description provided for @setTableLabelHint.
  ///
  /// In en, this message translates to:
  /// **'Label (e.g. 1, 2, Patio A)'**
  String get setTableLabelHint;

  /// No description provided for @setActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get setActive;

  /// No description provided for @setJobKitchenTicket.
  ///
  /// In en, this message translates to:
  /// **'Kitchen ticket'**
  String get setJobKitchenTicket;

  /// No description provided for @setJobCustomerReceipt.
  ///
  /// In en, this message translates to:
  /// **'Customer receipt'**
  String get setJobCustomerReceipt;

  /// No description provided for @setJobTestPage.
  ///
  /// In en, this message translates to:
  /// **'Test page'**
  String get setJobTestPage;

  /// No description provided for @setJobQueued.
  ///
  /// In en, this message translates to:
  /// **'Queued'**
  String get setJobQueued;

  /// No description provided for @setJobPrinting.
  ///
  /// In en, this message translates to:
  /// **'Printing…'**
  String get setJobPrinting;

  /// No description provided for @setJobPrinted.
  ///
  /// In en, this message translates to:
  /// **'Printed'**
  String get setJobPrinted;

  /// No description provided for @setJobFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get setJobFailed;

  /// No description provided for @setJobStatusError.
  ///
  /// In en, this message translates to:
  /// **'{status} — {error}'**
  String setJobStatusError(String status, String error);

  /// No description provided for @setRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get setRetry;

  /// No description provided for @setDiscard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get setDiscard;

  /// No description provided for @setCloudSync.
  ///
  /// In en, this message translates to:
  /// **'Cloud sync'**
  String get setCloudSync;

  /// No description provided for @setCloudBackingUp.
  ///
  /// In en, this message translates to:
  /// **'Backing up to your Supabase'**
  String get setCloudBackingUp;

  /// No description provided for @setCloudNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'Not configured'**
  String get setCloudNotConfigured;

  /// No description provided for @setCloudConfiguredSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{url}\nOptional — the POS works fully offline.'**
  String setCloudConfiguredSubtitle(String url);

  /// No description provided for @setCloudNotConfiguredSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Back up and sync to your own Supabase project. Optional; the POS works fully offline without it.'**
  String get setCloudNotConfiguredSubtitle;

  /// No description provided for @setSetUp.
  ///
  /// In en, this message translates to:
  /// **'Set up'**
  String get setSetUp;

  /// No description provided for @setSignedInAs.
  ///
  /// In en, this message translates to:
  /// **'Signed in as {email}'**
  String setSignedInAs(String email);

  /// No description provided for @setSignInRequired.
  ///
  /// In en, this message translates to:
  /// **'Restaurant sign-in required'**
  String get setSignInRequired;

  /// No description provided for @setSignedInSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sync and online orders use this secure login.'**
  String get setSignedInSubtitle;

  /// No description provided for @setSignInRequiredSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Cloud features need your restaurant Supabase login so your data stays private. (Customers never get it.)'**
  String get setSignInRequiredSubtitle;

  /// No description provided for @setSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get setSignOut;

  /// No description provided for @setSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get setSignIn;

  /// No description provided for @setLastSynced.
  ///
  /// In en, this message translates to:
  /// **'Last synced {time}'**
  String setLastSynced(String time);

  /// No description provided for @setSyncNow.
  ///
  /// In en, this message translates to:
  /// **'Sync now'**
  String get setSyncNow;

  /// No description provided for @setRestoreFromCloud.
  ///
  /// In en, this message translates to:
  /// **'Restore from cloud'**
  String get setRestoreFromCloud;

  /// No description provided for @setCustomerQr.
  ///
  /// In en, this message translates to:
  /// **'Customer connect code'**
  String get setCustomerQr;

  /// No description provided for @setCustomerQrTitle.
  ///
  /// In en, this message translates to:
  /// **'Scan to order'**
  String get setCustomerQrTitle;

  /// No description provided for @setCustomerQrHint.
  ///
  /// In en, this message translates to:
  /// **'Customers scan this with the ordering app to add your restaurant and preorder for pickup.'**
  String get setCustomerQrHint;

  /// No description provided for @setRestaurantSignIn.
  ///
  /// In en, this message translates to:
  /// **'Restaurant sign-in'**
  String get setRestaurantSignIn;

  /// No description provided for @setSignInBody.
  ///
  /// In en, this message translates to:
  /// **'Sign in with the Supabase user you created for this restaurant. This keeps your data private from customers.'**
  String get setSignInBody;

  /// No description provided for @setEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get setEmail;

  /// No description provided for @setPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get setPassword;

  /// No description provided for @setSignedInMsg.
  ///
  /// In en, this message translates to:
  /// **'Signed in.'**
  String get setSignedInMsg;

  /// No description provided for @setSignInFailed.
  ///
  /// In en, this message translates to:
  /// **'Sign-in failed: {error}'**
  String setSignInFailed(String error);

  /// No description provided for @setSignedOutMsg.
  ///
  /// In en, this message translates to:
  /// **'Signed out.'**
  String get setSignedOutMsg;

  /// No description provided for @setSyncedMsg.
  ///
  /// In en, this message translates to:
  /// **'Synced: {pulled} in, {pushed} out.'**
  String setSyncedMsg(int pulled, int pushed);

  /// No description provided for @setSyncFailed.
  ///
  /// In en, this message translates to:
  /// **'Sync failed: {error}'**
  String setSyncFailed(String error);

  /// No description provided for @setRestoreTitle.
  ///
  /// In en, this message translates to:
  /// **'Restore from cloud?'**
  String get setRestoreTitle;

  /// No description provided for @setRestoreBody.
  ///
  /// In en, this message translates to:
  /// **'Pulls the full history from your Supabase and applies it to this device. Use this on a new or wiped tablet. Existing local data is merged (last write wins), never wiped.'**
  String get setRestoreBody;

  /// No description provided for @setRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get setRestore;

  /// No description provided for @setRestoredMsg.
  ///
  /// In en, this message translates to:
  /// **'Restored {pulled} changes from the cloud.'**
  String setRestoredMsg(int pulled);

  /// No description provided for @setRestoreFailed.
  ///
  /// In en, this message translates to:
  /// **'Restore failed: {error}'**
  String setRestoreFailed(String error);

  /// No description provided for @setYourSupabaseProject.
  ///
  /// In en, this message translates to:
  /// **'Your Supabase project'**
  String get setYourSupabaseProject;

  /// No description provided for @setSupabaseBody.
  ///
  /// In en, this message translates to:
  /// **'Enter your project URL and anon (public) key. Create a \"sync_changes\" table first — see the setup SQL in the docs. Leave the URL empty to turn sync off.'**
  String get setSupabaseBody;

  /// No description provided for @setProjectUrl.
  ///
  /// In en, this message translates to:
  /// **'Project URL'**
  String get setProjectUrl;

  /// No description provided for @setAnonKey.
  ///
  /// In en, this message translates to:
  /// **'Anon key'**
  String get setAnonKey;

  /// No description provided for @navAdmin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get navAdmin;

  /// No description provided for @roleOwner.
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get roleOwner;

  /// No description provided for @roleManager.
  ///
  /// In en, this message translates to:
  /// **'Manager'**
  String get roleManager;

  /// No description provided for @roleServer.
  ///
  /// In en, this message translates to:
  /// **'Server'**
  String get roleServer;

  /// No description provided for @roleSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get roleSignIn;

  /// No description provided for @roleSwitchUser.
  ///
  /// In en, this message translates to:
  /// **'Switch user'**
  String get roleSwitchUser;

  /// No description provided for @roleSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get roleSignOut;

  /// No description provided for @roleNoStaffYet.
  ///
  /// In en, this message translates to:
  /// **'No staff set up yet'**
  String get roleNoStaffYet;

  /// No description provided for @roleAccessRequired.
  ///
  /// In en, this message translates to:
  /// **'Manager access required'**
  String get roleAccessRequired;

  /// No description provided for @pinEnterTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get pinEnterTitle;

  /// No description provided for @pinNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get pinNameLabel;

  /// No description provided for @pinFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'4-digit PIN'**
  String get pinFieldLabel;

  /// No description provided for @pinIncorrect.
  ///
  /// In en, this message translates to:
  /// **'Incorrect name or PIN'**
  String get pinIncorrect;

  /// No description provided for @pinUnlock.
  ///
  /// In en, this message translates to:
  /// **'Unlock'**
  String get pinUnlock;

  /// No description provided for @adminStaffSection.
  ///
  /// In en, this message translates to:
  /// **'Staff & roles'**
  String get adminStaffSection;

  /// No description provided for @adminAddStaff.
  ///
  /// In en, this message translates to:
  /// **'Add staff'**
  String get adminAddStaff;

  /// No description provided for @adminManageStaffOwnerOnly.
  ///
  /// In en, this message translates to:
  /// **'Only an owner can manage staff.'**
  String get adminManageStaffOwnerOnly;

  /// No description provided for @adminNewStaff.
  ///
  /// In en, this message translates to:
  /// **'New staff'**
  String get adminNewStaff;

  /// No description provided for @adminEditStaff.
  ///
  /// In en, this message translates to:
  /// **'Edit staff'**
  String get adminEditStaff;

  /// No description provided for @adminStaffName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get adminStaffName;

  /// No description provided for @adminStaffRole.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get adminStaffRole;

  /// No description provided for @adminStaffNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a name.'**
  String get adminStaffNameRequired;

  /// No description provided for @adminStaffPinRequired.
  ///
  /// In en, this message translates to:
  /// **'Set a 4-digit PIN.'**
  String get adminStaffPinRequired;

  /// No description provided for @adminStaffPinKeepHint.
  ///
  /// In en, this message translates to:
  /// **'Leave blank to keep the current PIN.'**
  String get adminStaffPinKeepHint;

  /// No description provided for @adminCannotDeleteLastOwner.
  ///
  /// In en, this message translates to:
  /// **'Can\'t remove the last owner.'**
  String get adminCannotDeleteLastOwner;

  /// No description provided for @adminRemoveStaffConfirm.
  ///
  /// In en, this message translates to:
  /// **'Remove {name}?'**
  String adminRemoveStaffConfirm(String name);

  /// No description provided for @adminBootstrapTitle.
  ///
  /// In en, this message translates to:
  /// **'Set up staff access'**
  String get adminBootstrapTitle;

  /// No description provided for @adminBootstrapBody.
  ///
  /// In en, this message translates to:
  /// **'Create the first owner account to turn on role-based access. Until then, everyone has full access.'**
  String get adminBootstrapBody;

  /// No description provided for @adminCreateFirstOwner.
  ///
  /// In en, this message translates to:
  /// **'Create the first owner'**
  String get adminCreateFirstOwner;

  /// No description provided for @adminManagementSection.
  ///
  /// In en, this message translates to:
  /// **'Management'**
  String get adminManagementSection;

  /// No description provided for @adminComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get adminComingSoon;

  /// No description provided for @adminOnlineAuth.
  ///
  /// In en, this message translates to:
  /// **'Online authorizations'**
  String get adminOnlineAuth;

  /// No description provided for @adminOnlineAuthBody.
  ///
  /// In en, this message translates to:
  /// **'When connected to your backend, high-risk actions can require a one-time passcode sent to the owner.'**
  String get adminOnlineAuthBody;

  /// No description provided for @adminDiscounts.
  ///
  /// In en, this message translates to:
  /// **'Discounts & comps'**
  String get adminDiscounts;

  /// No description provided for @adminEndOfDay.
  ///
  /// In en, this message translates to:
  /// **'End-of-day cash count'**
  String get adminEndOfDay;

  /// No description provided for @adminExport.
  ///
  /// In en, this message translates to:
  /// **'Export data'**
  String get adminExport;

  /// No description provided for @itemCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Item code (optional)'**
  String get itemCodeLabel;

  /// No description provided for @itemNameSecondaryLabel.
  ///
  /// In en, this message translates to:
  /// **'Second name (optional)'**
  String get itemNameSecondaryLabel;

  /// No description provided for @itemDescriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description (optional)'**
  String get itemDescriptionLabel;

  /// No description provided for @itemFieldsSection.
  ///
  /// In en, this message translates to:
  /// **'Custom fields'**
  String get itemFieldsSection;

  /// No description provided for @itemFieldLabelHint.
  ///
  /// In en, this message translates to:
  /// **'Field'**
  String get itemFieldLabelHint;

  /// No description provided for @itemFieldValueHint.
  ///
  /// In en, this message translates to:
  /// **'Value'**
  String get itemFieldValueHint;

  /// No description provided for @itemAddField.
  ///
  /// In en, this message translates to:
  /// **'Add field'**
  String get itemAddField;

  /// No description provided for @itemFieldCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom…'**
  String get itemFieldCustom;

  /// No description provided for @fieldPresetDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get fieldPresetDescription;

  /// No description provided for @fieldPresetIngredients.
  ///
  /// In en, this message translates to:
  /// **'Ingredients'**
  String get fieldPresetIngredients;

  /// No description provided for @fieldPresetAllergens.
  ///
  /// In en, this message translates to:
  /// **'Allergens'**
  String get fieldPresetAllergens;

  /// No description provided for @fieldPresetSpice.
  ///
  /// In en, this message translates to:
  /// **'Spice level'**
  String get fieldPresetSpice;

  /// No description provided for @fieldPresetNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get fieldPresetNotes;

  /// No description provided for @itemImagesSection.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get itemImagesSection;

  /// No description provided for @itemAddImage.
  ///
  /// In en, this message translates to:
  /// **'Add photo'**
  String get itemAddImage;

  /// No description provided for @itemImageLabelHint.
  ///
  /// In en, this message translates to:
  /// **'Label'**
  String get itemImageLabelHint;

  /// No description provided for @itemSaveFirstForPhotos.
  ///
  /// In en, this message translates to:
  /// **'Save the item first to add photos.'**
  String get itemSaveFirstForPhotos;

  /// No description provided for @itemRenameImage.
  ///
  /// In en, this message translates to:
  /// **'Rename photo'**
  String get itemRenameImage;

  /// No description provided for @captureImportFromPhoto.
  ///
  /// In en, this message translates to:
  /// **'Import from photo'**
  String get captureImportFromPhoto;

  /// No description provided for @captureTemplatesTitle.
  ///
  /// In en, this message translates to:
  /// **'Capture templates'**
  String get captureTemplatesTitle;

  /// No description provided for @captureNewTemplate.
  ///
  /// In en, this message translates to:
  /// **'New template'**
  String get captureNewTemplate;

  /// No description provided for @captureNoTemplates.
  ///
  /// In en, this message translates to:
  /// **'No templates yet. Create one to map where each field sits on a menu photo.'**
  String get captureNoTemplates;

  /// No description provided for @captureTemplateNameHint.
  ///
  /// In en, this message translates to:
  /// **'Template name'**
  String get captureTemplateNameHint;

  /// No description provided for @captureRenameTemplate.
  ///
  /// In en, this message translates to:
  /// **'Rename template'**
  String get captureRenameTemplate;

  /// No description provided for @captureDeleteTemplate.
  ///
  /// In en, this message translates to:
  /// **'Delete template'**
  String get captureDeleteTemplate;

  /// No description provided for @captureDeleteTemplateConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete template \"{name}\"?'**
  String captureDeleteTemplateConfirm(String name);

  /// No description provided for @captureTemplateEditorTitle.
  ///
  /// In en, this message translates to:
  /// **'Template'**
  String get captureTemplateEditorTitle;

  /// No description provided for @capturePickSamplePhoto.
  ///
  /// In en, this message translates to:
  /// **'Pick a sample photo'**
  String get capturePickSamplePhoto;

  /// No description provided for @captureBigBlockHint.
  ///
  /// In en, this message translates to:
  /// **'Drag the large box over one item, then add labeled regions inside it.'**
  String get captureBigBlockHint;

  /// No description provided for @captureAddRegion.
  ///
  /// In en, this message translates to:
  /// **'Add region'**
  String get captureAddRegion;

  /// No description provided for @captureRegionField.
  ///
  /// In en, this message translates to:
  /// **'Field'**
  String get captureRegionField;

  /// No description provided for @captureRegionLabel.
  ///
  /// In en, this message translates to:
  /// **'Label'**
  String get captureRegionLabel;

  /// No description provided for @captureDeleteRegion.
  ///
  /// In en, this message translates to:
  /// **'Delete region'**
  String get captureDeleteRegion;

  /// No description provided for @captureSaveTemplate.
  ///
  /// In en, this message translates to:
  /// **'Save template'**
  String get captureSaveTemplate;

  /// No description provided for @captureTemplateNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Name the template.'**
  String get captureTemplateNameRequired;

  /// No description provided for @captureNeedsBlockAndRegion.
  ///
  /// In en, this message translates to:
  /// **'Draw the big box and at least one region.'**
  String get captureNeedsBlockAndRegion;

  /// No description provided for @captureFieldCode.
  ///
  /// In en, this message translates to:
  /// **'Code'**
  String get captureFieldCode;

  /// No description provided for @captureFieldName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get captureFieldName;

  /// No description provided for @captureFieldNameSecondary.
  ///
  /// In en, this message translates to:
  /// **'Second name'**
  String get captureFieldNameSecondary;

  /// No description provided for @captureFieldPrice.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get captureFieldPrice;

  /// No description provided for @captureFieldAttribute.
  ///
  /// In en, this message translates to:
  /// **'Custom field'**
  String get captureFieldAttribute;

  /// No description provided for @captureFieldImage.
  ///
  /// In en, this message translates to:
  /// **'Photo'**
  String get captureFieldImage;

  /// No description provided for @captureTitle.
  ///
  /// In en, this message translates to:
  /// **'Import from photo'**
  String get captureTitle;

  /// No description provided for @capturePickPhoto.
  ///
  /// In en, this message translates to:
  /// **'Pick menu photo'**
  String get capturePickPhoto;

  /// No description provided for @captureChooseTemplate.
  ///
  /// In en, this message translates to:
  /// **'Template'**
  String get captureChooseTemplate;

  /// No description provided for @captureChooseCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get captureChooseCategory;

  /// No description provided for @captureRunningOcr.
  ///
  /// In en, this message translates to:
  /// **'Reading text…'**
  String get captureRunningOcr;

  /// No description provided for @captureCaptureItem.
  ///
  /// In en, this message translates to:
  /// **'Capture item'**
  String get captureCaptureItem;

  /// No description provided for @captureDraftCount.
  ///
  /// In en, this message translates to:
  /// **'{count} captured'**
  String captureDraftCount(int count);

  /// No description provided for @captureReviewAction.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get captureReviewAction;

  /// No description provided for @captureOcrLanguageMissing.
  ///
  /// In en, this message translates to:
  /// **'No OCR language pack found. Add Chinese or English in Windows Settings → Time & language → Language.'**
  String get captureOcrLanguageMissing;

  /// No description provided for @captureSelectTemplateFirst.
  ///
  /// In en, this message translates to:
  /// **'Choose a template first.'**
  String get captureSelectTemplateFirst;

  /// No description provided for @captureSelectPhotoFirst.
  ///
  /// In en, this message translates to:
  /// **'Choose a photo first.'**
  String get captureSelectPhotoFirst;

  /// No description provided for @captureReviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Review drafts'**
  String get captureReviewTitle;

  /// No description provided for @captureSaveAll.
  ///
  /// In en, this message translates to:
  /// **'Save all'**
  String get captureSaveAll;

  /// No description provided for @captureDiscardDraft.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get captureDiscardDraft;

  /// No description provided for @captureNoDrafts.
  ///
  /// In en, this message translates to:
  /// **'Nothing captured yet.'**
  String get captureNoDrafts;

  /// No description provided for @captureSavedCount.
  ///
  /// In en, this message translates to:
  /// **'Saved {count} items'**
  String captureSavedCount(int count);

  /// No description provided for @captureUnsupportedPlatform.
  ///
  /// In en, this message translates to:
  /// **'Photo import runs on Windows for now.'**
  String get captureUnsupportedPlatform;

  /// No description provided for @captureTemplatesShort.
  ///
  /// In en, this message translates to:
  /// **'Templates'**
  String get captureTemplatesShort;

  /// No description provided for @captureLabelsToggle.
  ///
  /// In en, this message translates to:
  /// **'Labels'**
  String get captureLabelsToggle;

  /// No description provided for @captureCreateTemplate.
  ///
  /// In en, this message translates to:
  /// **'Create a template'**
  String get captureCreateTemplate;

  /// No description provided for @captureResetRegions.
  ///
  /// In en, this message translates to:
  /// **'Reset layout'**
  String get captureResetRegions;

  /// No description provided for @setSecondNameSection.
  ///
  /// In en, this message translates to:
  /// **'Second name display'**
  String get setSecondNameSection;

  /// No description provided for @setSecondNameHint.
  ///
  /// In en, this message translates to:
  /// **'Where the optional second (e.g. native-language) name appears.'**
  String get setSecondNameHint;

  /// No description provided for @setSecondNameOrderScreen.
  ///
  /// In en, this message translates to:
  /// **'On order screen'**
  String get setSecondNameOrderScreen;

  /// No description provided for @setSecondNameKitchen.
  ///
  /// In en, this message translates to:
  /// **'On kitchen ticket'**
  String get setSecondNameKitchen;

  /// No description provided for @setSecondNameReceipt.
  ///
  /// In en, this message translates to:
  /// **'On customer receipt'**
  String get setSecondNameReceipt;

  /// No description provided for @setSecondNameLanguage.
  ///
  /// In en, this message translates to:
  /// **'Second name language'**
  String get setSecondNameLanguage;

  /// No description provided for @setSecondNameLanguageHint.
  ///
  /// In en, this message translates to:
  /// **'Customers see this name first when their app is in this language.'**
  String get setSecondNameLanguageHint;

  /// No description provided for @setSecondNameLanguageNone.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get setSecondNameLanguageNone;

  /// No description provided for @setHelp.
  ///
  /// In en, this message translates to:
  /// **'User guide'**
  String get setHelp;

  /// No description provided for @setHelpSubtitle.
  ///
  /// In en, this message translates to:
  /// **'How to set up and run the POS.'**
  String get setHelpSubtitle;

  /// No description provided for @helpTitle.
  ///
  /// In en, this message translates to:
  /// **'User guide'**
  String get helpTitle;

  /// No description provided for @helpWelcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get helpWelcomeTitle;

  /// No description provided for @helpWelcomeBody.
  ///
  /// In en, this message translates to:
  /// **'This is your point-of-sale. A short guide walks you through setup and daily use — take a look, or open it any time from Settings → User guide.'**
  String get helpWelcomeBody;

  /// No description provided for @helpOpenGuide.
  ///
  /// In en, this message translates to:
  /// **'Open guide'**
  String get helpOpenGuide;

  /// No description provided for @helpNotNow.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get helpNotNow;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
