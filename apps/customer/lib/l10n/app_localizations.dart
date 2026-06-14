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
