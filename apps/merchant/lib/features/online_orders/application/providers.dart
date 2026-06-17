import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:restaurant_domain/restaurant_domain.dart' as domain;

import '../../menu/application/providers.dart';
import '../../orders/application/providers.dart';
import '../../../core/settings/providers.dart';
import '../../sync/application/providers.dart';
import '../data/menu_publisher.dart';
import '../drivers/noop_online_order_channel.dart';
import '../drivers/supabase_online_order_channel.dart';
import 'inbox_service.dart';

/// The online-ordering bridge. Uses the same Supabase project as cloud
/// sync; a NoopOnlineOrderChannel when nothing is configured.
final onlineOrderChannelProvider = Provider<domain.OnlineOrderChannel>((ref) {
  final config = ref.watch(syncSettingsProvider).config;
  if (!config.isConfigured) return const NoopOnlineOrderChannel();
  final auth = ref.read(supabaseAuthProvider);
  return SupabaseOnlineOrderChannel(
    url: config.url!,
    anonKey: config.anonKey!,
    accessToken: auth?.accessToken,
  );
});

final menuPublisherProvider = Provider<MenuPublisher>(
  (ref) => MenuPublisher(
    menu: ref.watch(menuRepositoryProvider),
    settings: ref.watch(settingsRepositoryProvider),
  ),
);

final inboxServiceProvider = Provider<InboxService>(
  (ref) => InboxService(
    channel: ref.watch(onlineOrderChannelProvider),
    orders: ref.watch(orderRepositoryProvider),
    settings: ref.watch(settingsRepositoryProvider),
    publisher: ref.watch(menuPublisherProvider),
  ),
);

/// True when online ordering is available (Supabase configured).
final onlineOrderingEnabledProvider = Provider<bool>(
  (ref) => ref.watch(syncSettingsProvider).config.isConfigured,
);

/// Preorders in [status], polled every few seconds for the inbox.
final onlineOrdersByStatusProvider = StreamProvider.autoDispose
    .family<List<domain.IncomingOnlineOrder>, domain.OnlineOrderStatus>((
      ref,
      status,
    ) async* {
      final inbox = ref.watch(inboxServiceProvider);
      while (true) {
        yield await inbox.currentByStatus(status);
        await Future<void>.delayed(const Duration(seconds: 5));
      }
    });
