/// The extension slots of the merchant POS and the customer app.
///
/// The apps ship with no extensions. Which extensions are installed is decided
/// by a package named `restaurant_extensions`: this repo carries an empty one
/// (`packages/extensions`), and a build can point that name at another
/// implementation with a root `pubspec_overrides.yaml`.
///
/// Extensions only see what is defined here. They never open the database:
/// they read and change the menu through [MenuHost], which the app implements.
library;

import 'package:flutter/widgets.dart';
import 'package:restaurant_domain/restaurant_domain.dart';

/// One add-on to the merchant app.
abstract class MerchantExtension {
  const MerchantExtension();

  /// Buttons this extension adds to the Menu tab's toolbar.
  List<MenuToolbarAction> get menuToolbarActions => const [];
}

/// A button on the Menu tab's toolbar.
class MenuToolbarAction {
  const MenuToolbarAction({
    required this.id,
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final String id;
  final IconData icon;

  /// The button text for the app's current language.
  final String Function(Locale locale) label;

  final void Function(BuildContext context, MenuHost host) onPressed;
}

/// What an extension may read and change in the menu.
abstract class MenuHost {
  /// The whole menu, with every item fully loaded (attributes and modifier
  /// links included), so an edit can start from the complete item.
  Future<MenuSnapshot> loadMenu();

  /// Applies [changes] in one transaction: every change lands, or none does.
  ///
  /// Throws [MenuChangeRejected] before writing anything when a change is
  /// invalid, for example an item in a category that doesn't exist.
  Future<void> apply(MenuChangeSet changes);

  /// Whether this till publishes its menu to the online store and kiosks.
  bool get canPublish;

  /// Publishes the current menu. Returns the photos that failed to upload.
  Future<List<String>> publishMenu();
}

/// The menu at one moment.
class MenuSnapshot {
  const MenuSnapshot({
    required this.categories,
    required this.items,
    required this.modifierGroups,
  });

  final List<Category> categories;
  final List<MenuItem> items;
  final List<ModifierGroup> modifierGroups;
}

/// A batch of menu edits, applied together by [MenuHost.apply].
///
/// Items are written whole: an [upsertItems] entry replaces the stored item,
/// including its attributes and modifier links. Start every edit from the
/// item in a [MenuSnapshot].
class MenuChangeSet {
  const MenuChangeSet({
    this.upsertCategories = const [],
    this.upsertItems = const [],
    this.deleteItemIds = const [],
  });

  final List<Category> upsertCategories;
  final List<MenuItem> upsertItems;
  final List<String> deleteItemIds;

  bool get isEmpty =>
      upsertCategories.isEmpty && upsertItems.isEmpty && deleteItemIds.isEmpty;
}

/// One add-on to the customer app.
abstract class CustomerExtension {
  const CustomerExtension();

  /// Buttons this extension adds to the storefront menu's toolbar.
  List<StorefrontAction> get storefrontActions => const [];
}

/// A button on the customer app's storefront menu toolbar.
class StorefrontAction {
  const StorefrontAction({
    required this.id,
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final String id;
  final IconData icon;

  /// The button text for the app's current language.
  final String Function(Locale locale) label;

  final void Function(BuildContext context, StorefrontHost host) onPressed;
}

/// What an extension may do with the restaurant the customer app is
/// connected to. The customer app implements it.
abstract class StorefrontHost {
  /// The restaurant's published menu, or null when it hasn't published one.
  Future<PublishedMenu?> loadMenu();

  /// Places a pay-at-pickup preorder exactly as checkout does (it reaches
  /// the restaurant's inbox and this device's order history). Returns its id.
  Future<String> placePreorder(PreorderSubmission order);

  /// Opens the live status screen for a placed order.
  void openOrderStatus(BuildContext context, String orderId, Money total);

  /// The most recent orders at this restaurant placed with phone number
  /// [phone] (like a caller-ID lookup), newest first. In the customer app the
  /// search covers the orders placed from this device.
  Future<List<PastOrder>> recentOrders({required String phone, int limit = 3});

  /// Withdraws a placed order if the restaurant hasn't accepted it yet.
  /// Returns false when it's too late (accepted, paid or gone): then a person
  /// at the restaurant has to help.
  Future<bool> withdrawOrder(String orderId);
}

/// An order this customer placed earlier.
class PastOrder {
  const PastOrder({
    required this.placedAt,
    required this.lines,
    required this.status,
  });

  final DateTime placedAt;
  final List<PreorderLine> lines;
  final OnlineOrderStatus status;
}

/// A [MenuChangeSet] that [MenuHost.apply] refused. Nothing was written.
class MenuChangeRejected implements Exception {
  const MenuChangeRejected(this.message);

  final String message;

  @override
  String toString() => 'MenuChangeRejected: $message';
}
