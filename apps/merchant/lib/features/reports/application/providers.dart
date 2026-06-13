import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:restaurant_domain/restaurant_domain.dart' as domain;

import '../../../core/providers.dart';
import '../data/reports_repository.dart';

final reportsRepositoryProvider = Provider<ReportsRepository>(
  (ref) => ReportsRepository(ref.watch(databaseProvider)),
);

/// The calendar day shown on the Reports screen (defaults to today).
class ReportDateNotifier extends Notifier<DateTime> {
  @override
  DateTime build() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  void set(DateTime day) => state = DateTime(day.year, day.month, day.day);
}

final reportDateProvider = NotifierProvider<ReportDateNotifier, DateTime>(
  ReportDateNotifier.new,
);

final dailyReportProvider = StreamProvider.family<DailyReport, DateTime>(
  (ref, day) => ref.watch(reportsRepositoryProvider).watchDailyReport(day),
);

final closedOrdersProvider =
    StreamProvider.family<List<domain.Order>, DateTime>(
      (ref, day) => ref.watch(reportsRepositoryProvider).watchClosedOrders(day),
    );
