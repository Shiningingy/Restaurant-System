import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:restaurant_domain/restaurant_domain.dart' as domain;

import '../../../core/providers.dart';
import '../data/storefront_config.dart';
import '../drivers/supabase_storefront.dart';

final storefrontConfigRepositoryProvider = Provider<StorefrontConfigRepository>(
  (ref) => StorefrontConfigRepository(ref.watch(sharedPreferencesProvider)),
);

/// The connected storefront config. Refresh with `ref.invalidate` after
/// connecting/disconnecting.
class StorefrontConfigNotifier extends Notifier<StorefrontConfig> {
  @override
  StorefrontConfig build() =>
      ref.watch(storefrontConfigRepositoryProvider).config;

  Future<void> connect({required String url, required String anonKey}) async {
    await ref
        .read(storefrontConfigRepositoryProvider)
        .connect(url: url, anonKey: anonKey);
    state = ref.read(storefrontConfigRepositoryProvider).config;
  }

  Future<void> disconnect() async {
    await ref.read(storefrontConfigRepositoryProvider).disconnect();
    state = ref.read(storefrontConfigRepositoryProvider).config;
  }
}

final storefrontConfigProvider =
    NotifierProvider<StorefrontConfigNotifier, StorefrontConfig>(
      StorefrontConfigNotifier.new,
    );

/// The HTTP client for the connected storefront, or null when not
/// connected.
final storefrontProvider = Provider<SupabaseStorefront?>((ref) {
  final config = ref.watch(storefrontConfigProvider);
  if (!config.isConnected) return null;
  return SupabaseStorefront(url: config.url!, anonKey: config.anonKey!);
});

/// The published menu being browsed.
final menuProvider = FutureProvider<domain.PublishedMenu?>((ref) {
  final storefront = ref.watch(storefrontProvider);
  if (storefront == null) return Future.value(null);
  return storefront.fetchMenu();
});
