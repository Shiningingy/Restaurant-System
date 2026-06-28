import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:restaurant_domain/restaurant_domain.dart' as domain;

import '../../admin/domain/staff.dart';
import '../../admin/presentation/pin_dialog.dart';
import '../../orders/application/providers.dart';
import '../../payments/application/providers.dart';
import '../../printing/application/providers.dart';
import '../../../core/settings/providers.dart';
import '../../../core/l10n_ext.dart';
import '../../../core/labels.dart';
import '../application/providers.dart';
import '../data/reports_repository.dart';

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

    final dateFormat = DateFormat(
      'EEE, yyyy-MM-dd',
      Localizations.localeOf(context).toString(),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.repTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            tooltip: context.l10n.repPreviousDay,
            onPressed: () => ref
                .read(reportDateProvider.notifier)
                .set(day.subtract(const Duration(days: 1))),
          ),
          TextButton(
            onPressed: () => _pickDate(context, ref, day),
            child: Text(dateFormat.format(day)),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            tooltip: context.l10n.repNextDay,
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
                    context.l10n.repCollected,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  _CollectedTable(report: report),
                  const SizedBox(height: 24),
                ],
                if (report.itemSales.isNotEmpty) ...[
                  Text(
                    context.l10n.repItemSales,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  for (final item in report.itemSales)
                    ListTile(
                      dense: true,
                      leading: SizedBox(
                        width: 40,
                        child: Text(
                          context.l10n.repItemQty(item.qty),
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ),
                      title: Text(item.name),
                      trailing: Text(item.revenue.format()),
                    ),
                  const SizedBox(height: 24),
                ],
                Text(
                  context.l10n.repOrderHistory,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                if (orders.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(context.l10n.repNoClosedOrders),
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
          context.l10n.repOrders,
          '${report.ordersPaid}',
          report.ordersVoided == 0
              ? null
              : context.l10n.repOrdersVoided(report.ordersVoided),
        ),
        _card(
          context,
          context.l10n.repGrossSales,
          report.gross.format(),
          context.l10n.repSubtotalValue(report.subtotal.format()),
        ),
        _card(context, context.l10n.repTax, report.tax.format(), null),
        _card(context, context.l10n.repTips, report.tipsTotal.format(), null),
        if (report.comps.cents > 0)
          _card(context, context.l10n.repComps, report.comps.format(), null),
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
            title: Text(paymentMethodLabel(context, m.method)),
            subtitle: Text(
              m.tips.isZero
                  ? context.l10n.repPaymentsCount(m.count)
                  : context.l10n.repPaymentsCountTips(m.count, m.tips.format()),
            ),
            trailing: Text(m.amount.format()),
          ),
        ListTile(
          dense: true,
          title: Text(
            context.l10n.repTotalCollected,
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
    final typeLabel = order.type.label(context);
    final ref0 = '$typeLabel ${domain.orderRef(order.id)}';
    return ListTile(
      dense: true,
      leading: Icon(
        voided ? Icons.block : Icons.check_circle_outline,
        color: voided ? Theme.of(context).colorScheme.error : null,
      ),
      title: Text(voided ? context.l10n.repOrderVoidedSuffix(ref0) : ref0),
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
        ref.watch(receiptPrinterReadyProvider);

    final orderRef = domain.orderRef(order.id);
    return AlertDialog(
      title: Text(
        order.status == domain.OrderStatus.voided
            ? context.l10n.repOrderVoidedParen(orderRef)
            : orderRef,
      ),
      content: SizedBox(
        width: 400,
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final line in active)
              ListTile(
                dense: true,
                title: Text(
                  context.l10n.repLineQtyName(line.qty, line.nameSnapshot),
                ),
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
              title: Text(context.l10n.repTotal),
              trailing: Text(order.total.format()),
            ),
            for (final p in settled)
              ListTile(
                dense: true,
                title: Text(paymentMethodLabel(context, p.method)),
                subtitle: p.tip.isZero
                    ? null
                    : Text(context.l10n.repTipValue(p.tip.format())),
                trailing: Text(p.amount.format()),
              ),
          ],
        ),
      ),
      actions: [
        TextButton.icon(
          onPressed: () => _confirmDelete(context, ref),
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.error,
          ),
          icon: const Icon(Icons.delete_outline),
          label: Text(context.l10n.repDeleteOrder),
        ),
        if (canReprint)
          TextButton.icon(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              final l10n = context.l10n;
              await ref
                  .read(printServiceProvider)
                  .printCustomerReceipt(order.id);
              messenger.showSnackBar(
                SnackBar(content: Text(l10n.repReceiptQueued)),
              );
            },
            icon: const Icon(Icons.print_outlined),
            label: Text(context.l10n.repReprintReceipt),
          ),
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: Text(context.l10n.commonClose),
        ),
      ],
    );
  }

  /// Owner-only: permanently delete this order from history (clears test data).
  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final ok = await requirePermission(
      context,
      ref,
      AppPermission.deleteHistory,
    );
    if (!ok || !context.mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.repDeleteConfirmTitle),
        content: Text(context.l10n.repDeleteConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.commonCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.commonDelete),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await ref.read(orderRepositoryProvider).deleteOrder(order.id);
    if (context.mounted) Navigator.pop(context); // close the detail dialog
  }
}
