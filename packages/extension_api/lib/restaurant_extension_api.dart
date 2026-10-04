/// The extension slot of the merchant POS.
///
/// The app ships with no extensions. Which extensions are installed is decided
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

/// A [MenuChangeSet] that [MenuHost.apply] refused. Nothing was written.
class MenuChangeRejected implements Exception {
  const MenuChangeRejected(this.message);

  final String message;

  @override
  String toString() => 'MenuChangeRejected: $message';
}
