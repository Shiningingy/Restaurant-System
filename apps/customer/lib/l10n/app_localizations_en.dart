// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Preorder';

  @override
  String get languageMenuTooltip => 'Language';

  @override
  String get languageSystem => 'System default';

  @override
  String get connectTitle => 'Connect to a restaurant';

  @override
  String get connectAddTitle => 'Add a restaurant';

  @override
  String get connectIntro =>
      'Scan or enter the storefront your restaurant gave you to browse the menu and preorder for pickup.';

  @override
  String get connectUrlLabel => 'Storefront URL';

  @override
  String get connectKeyLabel => 'Access key';

  @override
  String get connectNameLabel => 'Restaurant name (optional)';

  @override
  String get connectScanButton => 'Scan QR code';

  @override
  String get connectUploadQr => 'Upload QR image';

  @override
  String get connectQrImageInvalid =>
      'No restaurant QR code found in that image.';

  @override
  String get connectEnterManually => 'Enter details manually';

  @override
  String get connectOrDivider => 'or enter it by hand';

  @override
  String get connectButton => 'Connect';

  @override
  String get connectErrorEmptyFields => 'Enter the restaurant URL and key.';

  @override
  String get walletTitle => 'My restaurants';

  @override
  String get walletEmptyTitle => 'No restaurants yet';

  @override
  String get walletEmptyBody =>
      'Add a restaurant by scanning its QR code, or enter its link by hand.';

  @override
  String get walletAdd => 'Add restaurant';

  @override
  String get walletProfile => 'My details';

  @override
  String get walletShare => 'Share';

  @override
  String get walletRename => 'Rename';

  @override
  String get walletRenameLabel => 'Your nickname for this restaurant';

  @override
  String get walletRemove => 'Remove';

  @override
  String walletRemoveConfirm(String name) {
    return 'Remove $name from your restaurants?';
  }

  @override
  String get commonCancel => 'Cancel';

  @override
  String get kioskEnter => 'Kiosk mode';

  @override
  String get kioskEnterTitle => 'Switch to kiosk mode?';

  @override
  String kioskEnterBody(String name) {
    return 'This tablet becomes a self-order kiosk for $name. Customers can order but can\'t switch restaurant. To exit, long-press the top-left corner.';
  }

  @override
  String get kioskTapToOrder => 'Tap to order';

  @override
  String get kioskStart => 'Start order';

  @override
  String get kioskExit => 'Exit kiosk';

  @override
  String get kioskExitTitle => 'Exit kiosk mode?';

  @override
  String get kioskExitBody => 'This device returns to normal mode.';

  @override
  String get kioskNotConnected => 'Kiosk isn\'t set up yet.';

  @override
  String get kioskThankYou => 'Thank you!';

  @override
  String get kioskThankYouBody =>
      'Your order is in. Please pay at the counter.';

  @override
  String get kioskStartNewOrder => 'Start new order';

  @override
  String get kioskDefaultName => 'Kiosk';

  @override
  String get kioskSetup => 'Set up kiosk';

  @override
  String get kioskLoadingMenu => 'Loading menu…';

  @override
  String get kioskRetry => 'Retry';

  @override
  String get kioskBack => 'Back';

  @override
  String get kioskHeaderFallback => 'Order here';

  @override
  String get kioskCartEmpty => 'Your cart is empty';

  @override
  String get kioskReviewOrder => 'Review order';

  @override
  String get kioskReviewTitle => 'Your order';

  @override
  String get kioskAddMore => 'Add more';

  @override
  String get kioskPayAtCounter => 'Pay at counter';

  @override
  String get kioskPlacing => 'Placing…';

  @override
  String get kioskPayHereSoon => 'Pay here (soon)';

  @override
  String get kioskSubtotal => 'Subtotal';

  @override
  String get kioskTotal => 'Total';

  @override
  String get kioskOrderPlaced => 'Order placed!';

  @override
  String get kioskYourNumber => 'Your number';

  @override
  String get kioskPayAtCounterNote => 'Please pay at the counter.';

  @override
  String get kioskDone => 'Done';

  @override
  String get kioskAddToOrder => 'Add to order';

  @override
  String get kioskSubmitFailed =>
      'Could not place the order. Please ask staff.';

  @override
  String kioskCartSummary(int count, String total) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
    );
    return '$_temp0  ·  $total';
  }

  @override
  String kioskService(String pct) {
    return 'Service ($pct%)';
  }

  @override
  String kioskTax(String pct) {
    return 'Tax ($pct%)';
  }

  @override
  String kioskAddToOrderExtra(String extra) {
    return 'Add to order  ·  +$extra';
  }

  @override
  String kioskOrderName(int number) {
    return 'Kiosk $number';
  }

  @override
  String get kioskSetupTitle => 'Set up kiosk';

  @override
  String get kioskSetupBody =>
      'Sign in with the restaurant\'s store login to turn this device into a self-order kiosk. The login authorizes setup only — it isn\'t saved on the device.';

  @override
  String get kioskSetupEmail => 'Store email';

  @override
  String get kioskSetupPassword => 'Store password';

  @override
  String get kioskSetupNumber => 'Kiosk number';

  @override
  String get kioskSetupNumberHint =>
      'Shown on this kiosk\'s orders, e.g. Kiosk 3';

  @override
  String get kioskSetupStart => 'Set up kiosk';

  @override
  String get kioskSetupNoStore =>
      'Open a restaurant first, then set up the kiosk.';

  @override
  String kioskSetupSignInFailed(String error) {
    return 'Couldn\'t sign in: $error';
  }

  @override
  String get profileTitle => 'My details';

  @override
  String get profileIntro =>
      'Saved on this device to prefill your pickup orders. No account, no sign-in.';

  @override
  String get profileNameLabel => 'Name or nickname';

  @override
  String get profilePhoneLabel => 'Phone (optional)';

  @override
  String get profileEmailLabel => 'Email (optional)';

  @override
  String get profileNotifySection => 'Notify me when my order is ready';

  @override
  String get profileNotifyHint =>
      'Only works if the restaurant has turned on email/SMS notifications.';

  @override
  String get profileNotifyEmail => 'By email';

  @override
  String get profileNotifySms => 'By text message';

  @override
  String get profileSave => 'Save';

  @override
  String get profileSaved => 'Saved';

  @override
  String get scanTitle => 'Scan storefront QR';

  @override
  String get scanHint => 'Point your camera at the restaurant\'s QR code.';

  @override
  String get scanInvalid => 'That QR code isn\'t a restaurant link.';

  @override
  String get scanCameraNeeded =>
      'Camera access is needed to scan a restaurant\'s QR code.';

  @override
  String get scanAllowCamera => 'Allow camera';

  @override
  String get scanCameraBlocked =>
      'Camera access is turned off. Enable it for this app in Settings, then come back.';

  @override
  String get scanOpenSettings => 'Open settings';

  @override
  String get scanCameraError =>
      'Couldn\'t start the camera. Check that camera access is allowed in Settings.';

  @override
  String shareTitle(String name) {
    return 'Share $name';
  }

  @override
  String get shareHint => 'Let a friend scan this to add the same restaurant.';

  @override
  String get shareClose => 'Close';

  @override
  String get menuTitle => 'Menu';

  @override
  String get menuDisconnect => 'Disconnect';

  @override
  String get menuOptionsAvailable => 'Options available';

  @override
  String get menuEmpty => 'This restaurant has no menu published yet.';

  @override
  String menuLoadError(String error) {
    return 'Couldn\'t load the menu.\n$error';
  }

  @override
  String menuViewCart(int count, String total) {
    return 'View cart ($count) — $total';
  }

  @override
  String menuItemAdded(String name) {
    return 'Added $name';
  }

  @override
  String itemPriceDelta(String delta) {
    return '+$delta';
  }

  @override
  String itemAdd(String price) {
    return 'Add — $price';
  }

  @override
  String get cartTitle => 'Your order';

  @override
  String get cartEmpty => 'Your cart is empty.';

  @override
  String get cartTotal => 'Total';

  @override
  String get cartCheckout => 'Checkout';

  @override
  String get checkoutTitle => 'Checkout';

  @override
  String get checkoutNameLabel => 'Your name';

  @override
  String get checkoutPhoneLabel => 'Phone (optional)';

  @override
  String get checkoutPickupTime => 'Pickup time';

  @override
  String checkoutPickupLead(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: 'Ready about $minutes minutes after ordering at the earliest',
      one: 'Ready about 1 minute after ordering at the earliest',
    );
    return '$_temp0';
  }

  @override
  String checkoutPickupTooSoon(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other:
          'That\'s too soon — pickup is at least $minutes minutes away. Set to the earliest time.',
    );
    return '$_temp0';
  }

  @override
  String get checkoutSubtotal => 'Subtotal';

  @override
  String get checkoutEstimatedTax => 'Estimated tax';

  @override
  String get checkoutEstimateNote =>
      'Tax is estimated; the restaurant confirms the final total. Pay at the counter when you pick up.';

  @override
  String get checkoutTotal => 'Total';

  @override
  String get checkoutPayAtCounter => 'Pay at the counter when you pick up.';

  @override
  String get checkoutNameRequired => 'Please enter your name.';

  @override
  String checkoutOrderFailed(String error) {
    return 'Could not place the order: $error';
  }

  @override
  String get checkoutPlacePreorder => 'Place preorder';

  @override
  String get statusTitle => 'Your preorder';

  @override
  String get statusSendingHeadline => 'Sending your order…';

  @override
  String get statusSubmittedHeadline => 'Waiting for the restaurant';

  @override
  String get statusAcceptedHeadline => 'Accepted — being prepared';

  @override
  String get statusReadyHeadline => 'Ready for pickup!';

  @override
  String get statusPickedUpHeadline => 'Picked up — enjoy!';

  @override
  String get statusRejectedHeadline => 'Order declined';

  @override
  String get statusTimeProposedHeadline => 'New pickup time suggested';

  @override
  String get statusSubmittedDetail =>
      'The restaurant will confirm your order shortly.';

  @override
  String get statusAcceptedDetail =>
      'We\'ll let you know when it\'s ready to collect.';

  @override
  String get statusReadyDetail => 'Head to the counter to pick up and pay.';

  @override
  String get statusRejectedDetail =>
      'Sorry — the restaurant could not take this order.';

  @override
  String statusTimeProposedDetail(String time) {
    return 'The restaurant suggested $time instead. Approve to continue, or decline to cancel.';
  }

  @override
  String get statusApproveTime => 'Approve';

  @override
  String get statusDeclineTime => 'Decline';

  @override
  String statusTotalPayAtPickup(String total) {
    return 'Total $total — pay at pickup';
  }

  @override
  String get statusBackToMenu => 'Back to menu';

  @override
  String get ordersTitle => 'My orders';

  @override
  String get ordersEmpty =>
      'Orders you place here will show up here, with their status.';

  @override
  String get orderStatusSubmitted => 'Waiting';

  @override
  String get orderStatusTimeProposed => 'New time';

  @override
  String get orderStatusAccepted => 'Preparing';

  @override
  String get orderStatusReady => 'Ready';

  @override
  String get orderStatusPickedUp => 'Picked up';

  @override
  String get orderStatusRejected => 'Declined';

  @override
  String get orderMarkPickedUp => 'Picked up';

  @override
  String get orderMarkPickedUpFailed =>
      'Couldn\'t confirm pickup. Please try again.';

  @override
  String get orderNotifyAccepted =>
      'Your order was accepted and is being prepared.';

  @override
  String get orderNotifyReady => 'Your order is ready for pickup!';

  @override
  String get orderNotifyTimeProposed =>
      'The restaurant suggested a new pickup time — tap to review.';

  @override
  String get orderNotifyRejected => 'Your order was declined.';

  @override
  String get helpTitle => 'Help';

  @override
  String get helpWelcomeTitle => 'Welcome';

  @override
  String get helpWelcomeBody =>
      'Preorder from restaurants and pick up — no account needed. A quick guide shows you how; you can open it any time from the Help button.';

  @override
  String get helpOpenGuide => 'Show me';

  @override
  String get helpNotNow => 'Not now';
}
