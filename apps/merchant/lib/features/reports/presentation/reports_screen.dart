import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:restaurant_domain/restaurant_domain.dart' as domain;

import '../../orders/application/providers.dart';
import '../../payments/application/providers.dart';
import '../../printing/application/providers.dart';
import '../../settings/application/providers.dart';
import '../application/providers.dart';
import '../data/reports_repository.dart';

final _dateFormat = DateFormat('EEE, yyyy-MM-dd');
final _timeFormat = DateFormat('HH:mm');

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final day = ref.watch(reportDateProvider);
    final report = ref.watch(dailyReportProvider(day)).value;
    final orders = ref.watch(closedOrdersProvider(day)).value ?? const [];
    final today = DateTime.now();
    final isToday =
        day.year == today.year &&
        day.month == today.month &&
        day.day == today.day;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
        actions: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            tooltip: 'Previous day',
            onPressed: () => ref
                .read(reportDateProvider.notifier)
                .set(day.subtract(const Duration(days: 1))),
          ),
          TextButton(
            onPressed: () => _pickDate(context, ref, day),
            child: Text(_dateFormat.format(day)),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            tooltip: 'Next day',
            onPressed: isToday
                ? null
                : () => ref
                      .read(reportDateProvider.notifier)
                      .set(day.add(const Duration(days: 1))),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: report == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _SummaryCards(report: report),
                const SizedBox(height: 24),
                if (report.collected.isNotEmpty) ...[
                  Text(
                    'Collected',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  _CollectedTable(report: report),
                  const SizedBox(height: 24),
                ],
                if (report.itemSales.isNotEmpty) ...[
                  Text(
                    'Item sales',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  for (final item in report.itemSales)
                    ListTile(
                      dense: true,
                      leading: SizedBox(
                        width: 40,
                        child: Text(
                          '${item.qty}x',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ),
                      title: Text(item.name),
                      trailing: Text(item.revenue.format()),
                    ),
                  const SizedBox(height: 24),
                ],
                Text(
                  'Order history',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                if (orders.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('No closed orders on this day.'),
                  ),
                for (final order in orders) _OrderHistoryTile(order: order),
              ],
            ),
    );
  }

  Future<void> _pickDate(
    BuildContext context,
    WidgetRef ref,
    DateTime current,
  ) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      ref.read(reportDateProvider.notifier).set(picked);
    }
  }
}

class _SummaryCards extends StatelessWidget {
  final DailyReport report;

  const _SummaryCards({required this.report});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _card(
          context,
          'Orders',
          '${report.ordersPaid}',
          report.ordersVoided == 0 ? null : '${report.ordersVoided} voided',
        ),
        _card(
          context,
          'Gross sales',
          report.gross.format(),
          'Subtotal ${report.subtotal.format()}',
        ),
        _card(context, 'Tax', report.tax.format(), null),
        _card(context, 'Tips', report.tipsTotal.format(), null),
      ],
    );
  }

  Widget _card(
    BuildContext context,
    String label,
    String value,
    String? detail,
  ) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.labelMedium),
              const SizedBox(height: 4),
              Text(value, style: Theme.of(context).textTheme.headlineSmall),
              if (detail != null)
                Text(detail, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}

class _CollectedTable extends StatelessWidget {
  final DailyReport report;

  const _CollectedTable({required this.report});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final m in report.collected)
          ListTile(
            dense: true,
            title: Text(domain.paymentMethodLabel(m.method)),
            subtitle: Text(
              '${m.count} payment${m.count == 1 ? '' : 's'}'
              '${m.tips.isZero ? '' : ' - tips ${m.tips.format()}'}',
            ),
            trailing: Text(m.amount.format()),
          ),
        ListTile(
          dense: true,
          title: Text(
            'Total collected',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          trailing: Text(
            (report.collectedTotal + report.tipsTotal).format(),
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
      ],
    );
  }
}

class _OrderHistoryTile extends ConsumerWidget {
  final domain.Order order;

  const _OrderHistoryTile({required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final voided = order.status == domain.OrderStatus.voided;
    final typeLabel = switch (order.type) {
      domain.OrderType.dineIn => 'Dine-in',
      domain.OrderType.takeout => 'Takeout',
      domain.OrderType.online => 'Online',
    };
    return ListTile(
      dense: true,
      leading: Icon(
        voided ? Icons.block : Icons.check_circle_outline,
        color: voided ? Theme.of(context).colorScheme.error : null,
      ),
      title: Text(
        '$typeLabel ${domain.orderRef(order.id)}'
        '${voided ? ' - voided' : ''}',
      ),
      subtitle: Text(
        order.closedAt == null ? '' : _timeFormat.format(order.closedAt!),
      ),
      trailing: Text(order.total.format()),
      onTap: () => showDialog<void>(
        context: context,
        builder: (context) => _OrderDetailDialog(order: order),
      ),
    );
  }
}

class _OrderDetailDialog extends ConsumerWidget {
  final domain.Order order;

  const _OrderDetailDialog({required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lines = ref.watch(orderLinesProvider(order.id)).value ?? const [];
    final payments = ref.watch(orderPaymentsProvider(order.id)).value ?? [];
    final active = lines
        .where((l) => l.status == domain.OrderLineStatus.active)
        .toList();
    final settled = domain.settledPayments(payments).toList();
    final canReprint =
        order.status == domain.OrderStatus.paid &&
        ref.watch(printerSettingsProvider).isConfigured;

    return AlertDialog(
      title: Text(
        '${domain.orderRef(order.id)}'
        '${order.status == domain.OrderStatus.voided ? ' (voided)' : ''}',
      ),
      content: SizedBox(
        width: 400,
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final line in active)
              ListTile(
                dense: true,
                title: Text('${line.qty} x ${line.nameSnapshot}'),
                subtitle: line.modifiers.isEmpty
                    ? null
                    : Text(
                        line.modifiers.map((m) => m.nameSnapshot).join(', '),
                      ),
                trailing: Text(line.lineTotal.format()),
              ),
            const Divider(),
            ListTile(
              dense: true,
              title: const Text('Total'),
              trailing: Text(order.total.format()),
            ),
            for (final p in settled)
              ListTile(
                dense: true,
                title: Text(domain.paymentMethodLabel(p.method)),
                subtitle: p.tip.isZero ? null : Text('Tip ${p.tip.format()}'),
                trailing: Text(p.amount.format()),
              ),
          ],
        ),
      ),
      actions: [
        if (canReprint)
          TextButton.icon(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              await ref
                  .read(printServiceProvider)
                  .printCustomerReceipt(order.id);
              messenger.showSnackBar(
                const SnackBar(content: Text('Receipt queued.')),
              );
            },
            icon: const Icon(Icons.print_outlined),
            label: const Text('Reprint receipt'),
          ),
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
