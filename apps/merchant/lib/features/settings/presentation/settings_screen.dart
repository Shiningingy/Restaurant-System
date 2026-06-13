import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:restaurant_domain/restaurant_domain.dart' as domain;

import '../../../core/db/database.dart';
import '../../printing/application/providers.dart';
import '../application/providers.dart';
import '../data/settings_repository.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final taxRateBp = ref.watch(taxRateBpProvider);
    final tables = ref.watch(tablesProvider).value ?? const [];
    final printer = ref.watch(printerSettingsProvider);
    final receiptConfig = ref.watch(receiptConfigProvider);
    final printJobs = ref.watch(printJobsProvider).value ?? const [];

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Tax', style: Theme.of(context).textTheme.titleMedium),
          ListTile(
            title: const Text('Sales tax rate'),
            subtitle: const Text(
              'Applied to new orders; existing orders keep their rate.',
            ),
            trailing: Text(
              '${(taxRateBp / 100).toStringAsFixed(2)}%',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            onTap: () => _editTaxRate(context, ref, taxRateBp),
          ),
          const Divider(height: 32),
          Text('Payments', style: Theme.of(context).textTheme.titleMedium),
          const ListTile(
            leading: Icon(Icons.point_of_sale_outlined),
            title: Text('Card terminal: manual entry'),
            subtitle: Text(
              'Staff key the amount on the standalone terminal and record '
              'the outcome. Semi-integrated Moneris Go support arrives once '
              'the Moneris Cloud API access is set up.',
            ),
          ),
          const Divider(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Printing', style: Theme.of(context).textTheme.titleMedium),
              if (printer.isConfigured)
                TextButton.icon(
                  onPressed: () => _testPrint(context, ref),
                  icon: const Icon(Icons.print_outlined),
                  label: const Text('Test print'),
                ),
            ],
          ),
          ListTile(
            leading: const Icon(Icons.print_outlined),
            title: const Text('Network printer'),
            subtitle: Text(
              printer.isConfigured
                  ? '${printer.host}:${printer.port} - '
                        '${printer.paperWidthChars == domain.EscPos.width58mm ? "58" : "80"}mm paper'
                  : 'Not configured. ESC/POS over LAN (port 9100).',
            ),
            onTap: () => _editPrinter(context, ref, printer),
          ),
          ListTile(
            leading: const Icon(Icons.storefront_outlined),
            title: const Text('Business name on receipts'),
            subtitle: Text(receiptConfig.businessName),
            onTap: () async {
              final name = await _editText(
                context,
                title: 'Business name',
                current: receiptConfig.businessName,
              );
              if (name != null && name.isNotEmpty) {
                await ref
                    .read(receiptConfigProvider.notifier)
                    .setBusinessName(name);
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.notes_outlined),
            title: const Text('Receipt footer'),
            subtitle: Text(receiptConfig.footer),
            onTap: () async {
              final footer = await _editText(
                context,
                title: 'Receipt footer',
                current: receiptConfig.footer,
              );
              if (footer != null) {
                await ref
                    .read(receiptConfigProvider.notifier)
                    .setFooter(footer);
              }
            },
          ),
          if (printJobs.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(left: 16, top: 8),
              child: Text(
                'Print queue',
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ),
            for (final job in printJobs) _PrintJobTile(job: job),
          ],
          const Divider(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Tables', style: Theme.of(context).textTheme.titleMedium),
              TextButton.icon(
                onPressed: () => _editTable(context, ref, null),
                icon: const Icon(Icons.add),
                label: const Text('Table'),
              ),
            ],
          ),
          if (tables.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Add tables to enable dine-in orders.'),
            ),
          for (final t in tables)
            ListTile(
              leading: const Icon(Icons.table_restaurant_outlined),
              title: Text('Table ${t.label}'),
              subtitle: t.isActive ? null : const Text('Inactive'),
              onTap: () => _editTable(context, ref, t),
            ),
        ],
      ),
    );
  }

  Future<void> _editTaxRate(
    BuildContext context,
    WidgetRef ref,
    int currentBp,
  ) async {
    final controller = TextEditingController(
      text: (currentBp / 100).toStringAsFixed(2),
    );
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sales tax rate'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(suffixText: '%', labelText: 'Rate'),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    final percent = double.tryParse(controller.text);
    if (saved == true && percent != null && percent >= 0 && percent < 100) {
      await ref.read(taxRateBpProvider.notifier).setBp((percent * 100).round());
    }
  }

  Future<void> _testPrint(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final result = await ref.read(printServiceProvider).printTestPage();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          result.when(
            ok: (_) => 'Test page sent to the printer.',
            err: (e) => 'Test print failed: ${e.message}',
          ),
        ),
      ),
    );
  }

  Future<void> _editPrinter(
    BuildContext context,
    WidgetRef ref,
    PrinterSettings current,
  ) async {
    final hostController = TextEditingController(text: current.host ?? '');
    final portController = TextEditingController(text: current.port.toString());
    var widthChars = current.paperWidthChars;
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Network printer'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: hostController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Printer IP address',
                  helperText: 'Leave empty to disable printing.',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: portController,
                decoration: const InputDecoration(labelText: 'Port'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              SegmentedButton<int>(
                segments: const [
                  ButtonSegment(
                    value: domain.EscPos.width58mm,
                    label: Text('58mm paper'),
                  ),
                  ButtonSegment(
                    value: domain.EscPos.width80mm,
                    label: Text('80mm paper'),
                  ),
                ],
                selected: {widthChars},
                onSelectionChanged: (s) => setState(() => widthChars = s.first),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    if (saved == true) {
      await ref
          .read(printerSettingsProvider.notifier)
          .save(
            PrinterSettings(
              host: hostController.text.trim(),
              port:
                  int.tryParse(portController.text.trim()) ??
                  SettingsRepository.defaultPrinterPort,
              paperWidthChars: widthChars,
            ),
          );
      // A reachable printer may now be configured: retry what's queued.
      ref.read(printServiceProvider).kick();
    }
  }

  Future<String?> _editText(
    BuildContext context, {
    required String title,
    required String current,
  }) async {
    final controller = TextEditingController(text: current);
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    return saved == true ? controller.text.trim() : null;
  }

  Future<void> _editTable(
    BuildContext context,
    WidgetRef ref,
    domain.DiningTable? existing,
  ) async {
    final controller = TextEditingController(text: existing?.label ?? '');
    var isActive = existing?.isActive ?? true;
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(existing == null ? 'New table' : 'Edit table'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Label (e.g. 1, 2, Patio A)',
                ),
              ),
              if (existing != null)
                SwitchListTile(
                  title: const Text('Active'),
                  value: isActive,
                  onChanged: (v) => setState(() => isActive = v),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    if (saved == true && controller.text.trim().isNotEmpty) {
      await ref
          .read(tablesRepositoryProvider)
          .upsertTable(
            domain.DiningTable(
              id: existing?.id ?? domain.newId(),
              label: controller.text.trim(),
              isActive: isActive,
            ),
          );
    }
  }
}

class _PrintJobTile extends ConsumerWidget {
  final PrintJobRow job;

  const _PrintJobTile({required this.job});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kindLabel = switch (job.kind) {
      domain.PrintJobKind.kitchenTicket => 'Kitchen ticket',
      domain.PrintJobKind.customerReceipt => 'Customer receipt',
      domain.PrintJobKind.testPage => 'Test page',
    };
    final (icon, statusLabel) = switch (job.status) {
      domain.PrintJobStatus.queued => (Icons.schedule, 'Queued'),
      domain.PrintJobStatus.printing => (Icons.print, 'Printing...'),
      domain.PrintJobStatus.done => (Icons.check_circle_outline, 'Printed'),
      domain.PrintJobStatus.failed => (Icons.error_outline, 'Failed'),
    };
    final failed = job.status == domain.PrintJobStatus.failed;
    return ListTile(
      dense: true,
      leading: Icon(
        icon,
        color: failed ? Theme.of(context).colorScheme.error : null,
      ),
      title: Text(kindLabel),
      subtitle: Text(
        failed && job.lastError != null
            ? '$statusLabel - ${job.lastError}'
            : statusLabel,
      ),
      trailing: failed
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Retry',
                  onPressed: () =>
                      ref.read(printServiceProvider).retryJob(job.id),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: 'Discard',
                  onPressed: () =>
                      ref.read(printJobRepositoryProvider).deleteJob(job.id),
                ),
              ],
            )
          : null,
    );
  }
}
