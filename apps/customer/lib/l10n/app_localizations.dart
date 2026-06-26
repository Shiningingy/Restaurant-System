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

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Preorder'**
  String get appTitle;

  /// No description provided for @languageMenuTooltip.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageMenuTooltip;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get languageSystem;

  /// No description provided for @connectTitle.
  ///
  /// In en, this message translates to:
  /// **'Connect to a restaurant'**
  String get connectTitle;

  /// No description provided for @connectAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Add a restaurant'**
  String get connectAddTitle;

  /// No description provided for @connectIntro.
  ///
  /// In en, this message translates to:
  /// **'Scan or enter the storefront your restaurant gave you to browse the menu and preorder for pickup.'**
  String get connectIntro;

  /// No description provided for @connectUrlLabel.
  ///
  /// In en, this message translates to:
  /// **'Storefront URL'**
  String get connectUrlLabel;

  /// No description provided for @connectKeyLabel.
  ///
  /// In en, this message translates to:
  /// **'Access key'**
  String get connectKeyLabel;

  /// No description provided for @connectNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Restaurant name (optional)'**
  String get connectNameLabel;

  /// No description provided for @connectScanButton.
  ///
  /// In en, this message translates to:
  /// **'Scan QR code'**
  String get connectScanButton;

  /// No description provided for @connectUploadQr.
  ///
  /// In en, this message translates to:
  /// **'Upload QR image'**
  String get connectUploadQr;

  /// No description provided for @connectQrImageInvalid.
  ///
  /// In en, this message translates to:
  /// **'No restaurant QR code found in that image.'**
  String get connectQrImageInvalid;

  /// No description provided for @connectEnterManually.
  ///
  /// In en, this message translates to:
  /// **'Enter details manually'**
  String get connectEnterManually;

  /// No description provided for @connectOrDivider.
  ///
  /// In en, this message translates to:
  /// **'or enter it by hand'**
  String get connectOrDivider;

  /// No description provided for @connectButton.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get connectButton;

  /// No description provided for @connectErrorEmptyFields.
  ///
  /// In en, this message translates to:
  /// **'Enter the restaurant URL and key.'**
  String get connectErrorEmptyFields;

  /// No description provided for @walletTitle.
  ///
  /// In en, this message translates to:
  /// **'My restaurants'**
  String get walletTitle;

  /// No description provided for @walletEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No restaurants yet'**
  String get walletEmptyTitle;

  /// No description provided for @walletEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Add a restaurant by scanning its QR code, or enter its link by hand.'**
  String get walletEmptyBody;

  /// No description provided for @walletAdd.
  ///
  /// In en, this message translates to:
  /// **'Add restaurant'**
  String get walletAdd;

  /// No description provided for @walletProfile.
  ///
  /// In en, this message translates to:
  /// **'My details'**
  String get walletProfile;

  /// No description provided for @walletShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get walletShare;

  /// No description provided for @walletRename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get walletRename;

  /// No description provided for @walletRenameLabel.
  ///
  /// In en, this message translates to:
  /// **'Your nickname for this restaurant'**
  String get walletRenameLabel;

  /// No description provided for @walletRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get walletRemove;

  /// No description provided for @walletRemoveConfirm.
  ///
  /// In en, this message translates to:
  /// **'Remove {name} from your restaurants?'**
  String walletRemoveConfirm(String name);

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @kioskEnter.
  ///
  /// In en, this message translates to:
  /// **'Kiosk mode'**
  String get kioskEnter;

  /// No description provided for @kioskEnterTitle.
  ///
  /// In en, this message translates to:
  /// **'Switch to kiosk mode?'**
  String get kioskEnterTitle;

  /// No description provided for @kioskEnterBody.
  ///
  /// In en, this message translates to:
  /// **'This tablet becomes a self-order kiosk for {name}. Customers can order but can\'t switch restaurant. To exit, long-press the top-left corner.'**
  String kioskEnterBody(String name);

  /// No description provided for @kioskTapToOrder.
  ///
  /// In en, this message translates to:
  /// **'Tap to order'**
  String get kioskTapToOrder;

  /// No description provided for @kioskStart.
  ///
  /// In en, this message translates to:
  /// **'Start order'**
  String get kioskStart;

  /// No description provided for @kioskExit.
  ///
  /// In en, this message translates to:
  /// **'Exit kiosk'**
  String get kioskExit;

  /// No description provided for @kioskExitTitle.
  ///
  /// In en, this message translates to:
  /// **'Exit kiosk mode?'**
  String get kioskExitTitle;

  /// No description provided for @kioskExitBody.
  ///
  /// In en, this message translates to:
  /// **'This device returns to normal mode.'**
  String get kioskExitBody;

  /// No description provided for @kioskNotConnected.
  ///
  /// In en, this message translates to:
  /// **'Kiosk isn\'t set up yet.'**
  String get kioskNotConnected;

  /// No description provided for @kioskThankYou.
  ///
  /// In en, this message translates to:
  /// **'Thank you!'**
  String get kioskThankYou;

  /// No description provided for @kioskThankYouBody.
  ///
  /// In en, this message translates to:
  /// **'Your order is in. Please pay at the counter.'**
  String get kioskThankYouBody;

  /// No description provided for @kioskStartNewOrder.
  ///
  /// In en, this message translates to:
  /// **'Start new order'**
  String get kioskStartNewOrder;

  /// No description provided for @kioskDefaultName.
  ///
  /// In en, this message translates to:
  /// **'Kiosk'**
  String get kioskDefaultName;

  /// No description provided for @kioskSetup.
  ///
  /// In en, this message translates to:
  /// **'Set up kiosk'**
  String get kioskSetup;

  /// No description provided for @kioskLoadingMenu.
  ///
  /// In en, this message translates to:
  /// **'Loading menu…'**
  String get kioskLoadingMenu;

  /// No description provided for @kioskRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get kioskRetry;

  /// No description provided for @kioskBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get kioskBack;

  /// No description provided for @kioskHeaderFallback.
  ///
  /// In en, this message translates to:
  /// **'Order here'**
  String get kioskHeaderFallback;

  /// No description provided for @kioskCartEmpty.
  ///
  /// In en, this message translates to:
  /// **'Your cart is empty'**
  String get kioskCartEmpty;

  /// No description provided for @kioskReviewOrder.
  ///
  /// In en, this message translates to:
  /// **'Review order'**
  String get kioskReviewOrder;

  /// No description provided for @kioskReviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Your order'**
  String get kioskReviewTitle;

  /// No description provided for @kioskAddMore.
  ///
  /// In en, this message translates to:
  /// **'Add more'**
  String get kioskAddMore;

  /// No description provided for @kioskPayAtCounter.
  ///
  /// In en, this message translates to:
  /// **'Pay at counter'**
  String get kioskPayAtCounter;

  /// No description provided for @kioskPlacing.
  ///
  /// In en, this message translates to:
  /// **'Placing…'**
  String get kioskPlacing;

  /// No description provided for @kioskPayHereSoon.
  ///
  /// In en, this message translates to:
  /// **'Pay here (soon)'**
  String get kioskPayHereSoon;

  /// No description provided for @kioskSubtotal.
  ///
  /// In en, this message translates to:
  /// **'Subtotal'**
  String get kioskSubtotal;

  /// No description provided for @kioskTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get kioskTotal;

  /// No description provided for @kioskOrderPlaced.
  ///
  /// In en, this message translates to:
  /// **'Order placed!'**
  String get kioskOrderPlaced;

  /// No description provided for @kioskYourNumber.
  ///
  /// In en, this message translates to:
  /// **'Your number'**
  String get kioskYourNumber;

  /// No description provided for @kioskPayAtCounterNote.
  ///
  /// In en, this message translates to:
  /// **'Please pay at the counter.'**
  String get kioskPayAtCounterNote;

  /// No description provided for @kioskDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get kioskDone;

  /// No description provided for @kioskAddToOrder.
  ///
  /// In en, this message translates to:
  /// **'Add to order'**
  String get kioskAddToOrder;

  /// No description provided for @kioskSubmitFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not place the order. Please ask staff.'**
  String get kioskSubmitFailed;

  /// No description provided for @kioskCartSummary.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 item} other{{count} items}}  ·  {total}'**
  String kioskCartSummary(int count, String total);

  /// No description provided for @kioskService.
  ///
  /// In en, this message translates to:
  /// **'Service ({pct}%)'**
  String kioskService(String pct);

  /// No description provided for @kioskTax.
  ///
  /// In en, this message translates to:
  /// **'Tax ({pct}%)'**
  String kioskTax(String pct);

  /// No description provided for @kioskAddToOrderExtra.
  ///
  /// In en, this message translates to:
  /// **'Add to order  ·  +{extra}'**
  String kioskAddToOrderExtra(String extra);

  /// No description provided for @kioskAddToOrderTotal.
  ///
  /// In en, this message translates to:
  /// **'Add to order  ·  {total}'**
  String kioskAddToOrderTotal(String total);

  /// No description provided for @kioskOrderName.
  ///
  /// In en, this message translates to:
  /// **'Kiosk {number}'**
  String kioskOrderName(int number);

  /// No description provided for @kioskSetupTitle.
  ///
  /// In en, this message translates to:
  /// **'Set up kiosk'**
  String get kioskSetupTitle;

  /// No description provided for @kioskSetupBody.
  ///
  /// In en, this message translates to:
  /// **'Sign in with the restaurant\'s store login to turn this device into a self-order kiosk. The login authorizes setup only — it isn\'t saved on the device.'**
  String get kioskSetupBody;

  /// No description provided for @kioskSetupEmail.
  ///
  /// In en, this message translates to:
  /// **'Store email'**
  String get kioskSetupEmail;

  /// No description provided for @kioskSetupPassword.
  ///
  /// In en, this message translates to:
  /// **'Store password'**
  String get kioskSetupPassword;

  /// No description provided for @kioskSetupNumber.
  ///
  /// In en, this message translates to:
  /// **'Kiosk number'**
  String get kioskSetupNumber;

  /// No description provided for @kioskSetupNumberHint.
  ///
  /// In en, this message translates to:
  /// **'Shown on this kiosk\'s orders, e.g. Kiosk 3'**
  String get kioskSetupNumberHint;

  /// No description provided for @kioskSetupStart.
  ///
  /// In en, this message translates to:
  /// **'Set up kiosk'**
  String get kioskSetupStart;

  /// No description provided for @kioskSetupNoStore.
  ///
  /// In en, this message translates to:
  /// **'Open a restaurant first, then set up the kiosk.'**
  String get kioskSetupNoStore;

  /// No description provided for @kioskSetupSignInFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t sign in: {error}'**
  String kioskSetupSignInFailed(String error);

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'My details'**
  String get profileTitle;

  /// No description provided for @profileIntro.
  ///
  /// In en, this message translates to:
  /// **'Saved on this device to prefill your pickup orders. No account, no sign-in.'**
  String get profileIntro;

  /// No description provided for @profileNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name or nickname'**
  String get profileNameLabel;

  /// No description provided for @profilePhoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone (optional)'**
  String get profilePhoneLabel;

  /// No description provided for @profileEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email (optional)'**
  String get profileEmailLabel;

  /// No description provided for @profileNotifySection.
  ///
  /// In en, this message translates to:
  /// **'Notify me when my order is ready'**
  String get profileNotifySection;

  /// No description provided for @profileNotifyHint.
  ///
  /// In en, this message translates to:
  /// **'Only works if the restaurant has turned on email/SMS notifications.'**
  String get profileNotifyHint;

  /// No description provided for @profileNotifyEmail.
  ///
  /// In en, this message translates to:
  /// **'By email'**
  String get profileNotifyEmail;

  /// No description provided for @profileNotifySms.
  ///
  /// In en, this message translates to:
  /// **'By text message'**
  String get profileNotifySms;

  /// No description provided for @profileSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get profileSave;

  /// No description provided for @profileSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get profileSaved;

  /// No description provided for @scanTitle.
  ///
  /// In en, this message translates to:
  /// **'Scan storefront QR'**
  String get scanTitle;

  /// No description provided for @scanHint.
  ///
  /// In en, this message translates to:
  /// **'Point your camera at the restaurant\'s QR code.'**
  String get scanHint;

  /// No description provided for @scanInvalid.
  ///
  /// In en, this message translates to:
  /// **'That QR code isn\'t a restaurant link.'**
  String get scanInvalid;

  /// No description provided for @scanCameraNeeded.
  ///
  /// In en, this message translates to:
  /// **'Camera access is needed to scan a restaurant\'s QR code.'**
  String get scanCameraNeeded;

  /// No description provided for @scanAllowCamera.
  ///
  /// In en, this message translates to:
  /// **'Allow camera'**
  String get scanAllowCamera;

  /// No description provided for @scanCameraBlocked.
  ///
  /// In en, this message translates to:
  /// **'Camera access is turned off. Enable it for this app in Settings, then come back.'**
  String get scanCameraBlocked;

  /// No description provided for @scanOpenSettings.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get scanOpenSettings;

  /// No description provided for @scanCameraError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t start the camera. Check that camera access is allowed in Settings.'**
  String get scanCameraError;

  /// No description provided for @shareTitle.
  ///
  /// In en, this message translates to:
  /// **'Share {name}'**
  String shareTitle(String name);

  /// No description provided for @shareHint.
  ///
  /// In en, this message translates to:
  /// **'Let a friend scan this to add the same restaurant.'**
  String get shareHint;

  /// No description provided for @shareClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get shareClose;

  /// No description provided for @menuTitle.
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get menuTitle;

  /// No description provided for @menuDisconnect.
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get menuDisconnect;

  /// No description provided for @menuOptionsAvailable.
  ///
  /// In en, this message translates to:
  /// **'Options available'**
  String get menuOptionsAvailable;

  /// No description provided for @menuEmpty.
  ///
  /// In en, this message translates to:
  /// **'This restaurant has no menu published yet.'**
  String get menuEmpty;

  /// No description provided for @menuLoadError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load the menu.\n{error}'**
  String menuLoadError(String error);

  /// No description provided for @menuViewCart.
  ///
  /// In en, this message translates to:
  /// **'View cart ({count}) — {total}'**
  String menuViewCart(int count, String total);

  /// No description provided for @menuItemAdded.
  ///
  /// In en, this message translates to:
  /// **'Added {name}'**
  String menuItemAdded(String name);

  /// No description provided for @itemPriceDelta.
  ///
  /// In en, this message translates to:
  /// **'+{delta}'**
  String itemPriceDelta(String delta);

  /// No description provided for @itemAdd.
  ///
  /// In en, this message translates to:
  /// **'Add — {price}'**
  String itemAdd(String price);

  /// No description provided for @cartTitle.
  ///
  /// In en, this message translates to:
  /// **'Your order'**
  String get cartTitle;

  /// No description provided for @cartEmpty.
  ///
  /// In en, this message translates to:
  /// **'Your cart is empty.'**
  String get cartEmpty;

  /// No description provided for @cartTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get cartTotal;

  /// No description provided for @cartCheckout.
  ///
  /// In en, this message translates to:
  /// **'Checkout'**
  String get cartCheckout;

  /// No description provided for @checkoutTitle.
  ///
  /// In en, this message translates to:
  /// **'Checkout'**
  String get checkoutTitle;

  /// No description provided for @checkoutNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Your name'**
  String get checkoutNameLabel;

  /// No description provided for @checkoutPhoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone (optional)'**
  String get checkoutPhoneLabel;

  /// No description provided for @checkoutPickupTime.
  ///
  /// In en, this message translates to:
  /// **'Pickup time'**
  String get checkoutPickupTime;

  /// No description provided for @checkoutPickupLead.
  ///
  /// In en, this message translates to:
  /// **'{minutes, plural, =1{Ready about 1 minute after ordering at the earliest} other{Ready about {minutes} minutes after ordering at the earliest}}'**
  String checkoutPickupLead(int minutes);

  /// No description provided for @checkoutPickupTooSoon.
  ///
  /// In en, this message translates to:
  /// **'{minutes, plural, other{That\'s too soon — pickup is at least {minutes} minutes away. Set to the earliest time.}}'**
  String checkoutPickupTooSoon(int minutes);

  /// No description provided for @checkoutSubtotal.
  ///
  /// In en, this message translates to:
  /// **'Subtotal'**
  String get checkoutSubtotal;

  /// No description provided for @checkoutEstimatedTax.
  ///
  /// In en, this message translates to:
  /// **'Estimated tax'**
  String get checkoutEstimatedTax;

  /// No description provided for @checkoutEstimateNote.
  ///
  /// In en, this message translates to:
  /// **'Tax is estimated; the restaurant confirms the final total. Pay at the counter when you pick up.'**
  String get checkoutEstimateNote;

  /// No description provided for @checkoutTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get checkoutTotal;

  /// No description provided for @checkoutPayAtCounter.
  ///
  /// In en, this message translates to:
  /// **'Pay at the counter when you pick up.'**
  String get checkoutPayAtCounter;

  /// No description provided for @checkoutNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter your name.'**
  String get checkoutNameRequired;

  /// No description provided for @checkoutOrderFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not place the order: {error}'**
  String checkoutOrderFailed(String error);

  /// No description provided for @checkoutPlacePreorder.
  ///
  /// In en, this message translates to:
  /// **'Place preorder'**
  String get checkoutPlacePreorder;

  /// No description provided for @statusTitle.
  ///
  /// In en, this message translates to:
  /// **'Your preorder'**
  String get statusTitle;

  /// No description provided for @statusSendingHeadline.
  ///
  /// In en, this message translates to:
  /// **'Sending your order…'**
  String get statusSendingHeadline;

  /// No description provided for @statusSubmittedHeadline.
  ///
  /// In en, this message translates to:
  /// **'Waiting for the restaurant'**
  String get statusSubmittedHeadline;

  /// No description provided for @statusAcceptedHeadline.
  ///
  /// In en, this message translates to:
  /// **'Accepted — being prepared'**
  String get statusAcceptedHeadline;

  /// No description provided for @statusReadyHeadline.
  ///
  /// In en, this message translates to:
  /// **'Ready for pickup!'**
  String get statusReadyHeadline;

  /// No description provided for @statusPickedUpHeadline.
  ///
  /// In en, this message translates to:
  /// **'Picked up — enjoy!'**
  String get statusPickedUpHeadline;

  /// No description provided for @statusRejectedHeadline.
  ///
  /// In en, this message translates to:
  /// **'Order declined'**
  String get statusRejectedHeadline;

  /// No description provided for @statusTimeProposedHeadline.
  ///
  /// In en, this message translates to:
  /// **'New pickup time suggested'**
  String get statusTimeProposedHeadline;

  /// No description provided for @statusSubmittedDetail.
  ///
  /// In en, this message translates to:
  /// **'The restaurant will confirm your order shortly.'**
  String get statusSubmittedDetail;

  /// No description provided for @statusAcceptedDetail.
  ///
  /// In en, this message translates to:
  /// **'We\'ll let you know when it\'s ready to collect.'**
  String get statusAcceptedDetail;

  /// No description provided for @statusReadyDetail.
  ///
  /// In en, this message translates to:
  /// **'Head to the counter to pick up and pay.'**
  String get statusReadyDetail;

  /// No description provided for @statusRejectedDetail.
  ///
  /// In en, this message translates to:
  /// **'Sorry — the restaurant could not take this order.'**
  String get statusRejectedDetail;

  /// No description provided for @statusTimeProposedDetail.
  ///
  /// In en, this message translates to:
  /// **'The restaurant suggested {time} instead. Approve to continue, or decline to cancel.'**
  String statusTimeProposedDetail(String time);

  /// No description provided for @statusApproveTime.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get statusApproveTime;

  /// No description provided for @statusDeclineTime.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get statusDeclineTime;

  /// No description provided for @statusTotalPayAtPickup.
  ///
  /// In en, this message translates to:
  /// **'Total {total} — pay at pickup'**
  String statusTotalPayAtPickup(String total);

  /// No description provided for @statusBackToMenu.
  ///
  /// In en, this message translates to:
  /// **'Back to menu'**
  String get statusBackToMenu;

  /// No description provided for @ordersTitle.
  ///
  /// In en, this message translates to:
  /// **'My orders'**
  String get ordersTitle;

  /// No description provided for @ordersEmpty.
  ///
  /// In en, this message translates to:
  /// **'Orders you place here will show up here, with their status.'**
  String get ordersEmpty;

  /// No description provided for @orderStatusSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Waiting'**
  String get orderStatusSubmitted;

  /// No description provided for @orderStatusTimeProposed.
  ///
  /// In en, this message translates to:
  /// **'New time'**
  String get orderStatusTimeProposed;

  /// No description provided for @orderStatusAccepted.
  ///
  /// In en, this message translates to:
  /// **'Preparing'**
  String get orderStatusAccepted;

  /// No description provided for @orderStatusReady.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get orderStatusReady;

  /// No description provided for @orderStatusPickedUp.
  ///
  /// In en, this message translates to:
  /// **'Picked up'**
  String get orderStatusPickedUp;

  /// No description provided for @orderStatusRejected.
  ///
  /// In en, this message translates to:
  /// **'Declined'**
  String get orderStatusRejected;

  /// No description provided for @orderMarkPickedUp.
  ///
  /// In en, this message translates to:
  /// **'Picked up'**
  String get orderMarkPickedUp;

  /// No description provided for @orderMarkPickedUpFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t confirm pickup. Please try again.'**
  String get orderMarkPickedUpFailed;

  /// No description provided for @orderNotifyAccepted.
  ///
  /// In en, this message translates to:
  /// **'Your order was accepted and is being prepared.'**
  String get orderNotifyAccepted;

  /// No description provided for @orderNotifyReady.
  ///
  /// In en, this message translates to:
  /// **'Your order is ready for pickup!'**
  String get orderNotifyReady;

  /// No description provided for @orderNotifyTimeProposed.
  ///
  /// In en, this message translates to:
  /// **'The restaurant suggested a new pickup time — tap to review.'**
  String get orderNotifyTimeProposed;

  /// No description provided for @orderNotifyRejected.
  ///
  /// In en, this message translates to:
  /// **'Your order was declined.'**
  String get orderNotifyRejected;

  /// No description provided for @helpTitle.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get helpTitle;

  /// No description provided for @helpWelcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get helpWelcomeTitle;

  /// No description provided for @helpWelcomeBody.
  ///
  /// In en, this message translates to:
  /// **'Preorder from restaurants and pick up — no account needed. A quick guide shows you how; you can open it any time from the Help button.'**
  String get helpWelcomeBody;

  /// No description provided for @helpOpenGuide.
  ///
  /// In en, this message translates to:
  /// **'Show me'**
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
