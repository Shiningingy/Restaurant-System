import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:restaurant_domain/restaurant_domain.dart' as domain;

import '../../../core/providers.dart';
import '../../sync/application/providers.dart';
import '../data/order_repository.dart';

final orderRepositoryProvider = Provider<OrderRepository>(
  (ref) => OrderRepository(
    ref.watch(databaseProvider),
    journal: ref.watch(syncJournalProvider),
  ),
);

final openOrdersProvider = StreamProvider<List<domain.Order>>(
  (ref) => ref.watch(orderRepositoryProvider).watchOpenOrders(),
);

final orderProvider = StreamProvider.family<domain.Order?, String>(
  (ref, orderId) => ref.watch(orderRepositoryProvider).watchOrder(orderId),
);

final orderLinesProvider =
    StreamProvider.family<List<domain.OrderLine>, String>(
      (ref, orderId) => ref.watch(orderRepositoryProvider).watchLines(orderId),
    );
