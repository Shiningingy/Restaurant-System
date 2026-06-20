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
  String statusTotalPayAtPickup(String total) {
    return 'Total $total — pay at pickup';
  }

  @override
  String get statusBackToMenu => 'Back to menu';
}
