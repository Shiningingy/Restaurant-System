import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:restaurant_domain/restaurant_domain.dart' as domain;

import '../../../core/db/database.dart';
import '../../../core/l10n_ext.dart';
import '../../../core/settings/providers.dart';
import '../../../core/settings/settings_repository.dart';
import '../../../core/supabase_auth.dart';
import '../../printing/application/providers.dart';
import '../../sync/application/providers.dart';
import '../../sync/data/sync_settings.dart';

final _dateTimeFormat = DateFormat('yyyy-MM-dd HH:mm');

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final taxRateBp = ref.watch(taxRateBpProvider);
    final tables = ref.watch(tablesProvider).value ?? const [];
    final printer = ref.watch(printerSettingsProvider);
    final receiptConfig = ref.watch(receiptConfigProvider);
    final printJobs = ref.watch(printJobsProvider).value ?? const [];
    final localePref = ref.watch(localePreferenceProvider);

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.navSettings)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            context.l10n.setLanguage,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          ListTile(
            leading: const Icon(Icons.translate_outlined),
            title: Text(context.l10n.setLanguage),
            subtitle: Text(_languageLabel(context, localePref)),
            onTap: () => _editLanguage(context, ref, localePref),
          ),
          const Divider(height: 32),
          Text(
            context.l10n.setTax,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          ListTile(
            title: Text(context.l10n.setSalesTaxRate),
            subtitle: Text(context.l10n.setSalesTaxRateSubtitle),
            trailing: Text(
              '${(taxRateBp / 100).toStringAsFixed(2)}%',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            onTap: () => _editTaxRate(context, ref, taxRateBp),
          ),
          const Divider(height: 32),
          Text(
            context.l10n.setPayments,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          ListTile(
            leading: const Icon(Icons.point_of_sale_outlined),
            title: Text(context.l10n.setCardTerminalManual),
            subtitle: Text(context.l10n.setCardTerminalManualSubtitle),
          ),
          const Divider(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                context.l10n.setPrinting,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (printer.isConfigured)
                TextButton.icon(
                  onPressed: () => _testPrint(context, ref),
                  icon: const Icon(Icons.print_outlined),
                  label: Text(context.l10n.setTestPrint),
                ),
            ],
          ),
          ListTile(
            leading: const Icon(Icons.print_outlined),
            title: Text(context.l10n.setNetworkPrinter),
            subtitle: Text(
              printer.isConfigured
                  ? context.l10n.setPrinterConfigured(
                      printer.host!,
                      printer.port,
                      printer.paperWidthChars == domain.EscPos.width58mm
                          ? '58'
                          : '80',
                    )
                  : context.l10n.setPrinterNotConfigured,
            ),
            onTap: () => _editPrinter(context, ref, printer),
          ),
          ListTile(
            leading: const Icon(Icons.storefront_outlined),
            title: Text(context.l10n.setBusinessNameOnReceipts),
            subtitle: Text(receiptConfig.businessName),
            onTap: () async {
              final name = await _editText(
                context,
                title: context.l10n.setBusinessName,
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
            title: Text(context.l10n.setReceiptFooter),
            subtitle: Text(receiptConfig.footer),
            onTap: () async {
              final footer = await _editText(
                context,
                title: context.l10n.setReceiptFooter,
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
                context.l10n.setPrintQueue,
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ),
            for (final job in printJobs) _PrintJobTile(job: job),
          ],
          const Divider(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                context.l10n.setTables,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              TextButton.icon(
                onPressed: () => _editTable(context, ref, null),
                icon: const Icon(Icons.add),
                label: Text(context.l10n.setTableButton),
              ),
            ],
          ),
          if (tables.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(context.l10n.setAddTablesHint),
            ),
          for (final t in tables)
            ListTile(
              leading: const Icon(Icons.table_restaurant_outlined),
              title: Text(context.l10n.orderTableLabel(t.label)),
              subtitle: t.isActive ? null : Text(context.l10n.setInactive),
              onTap: () => _editTable(context, ref, t),
            ),
          const Divider(height: 32),
          const _CloudSyncSection(),
        ],
      ),
    );
  }

  String _languageLabel(BuildContext context, Locale? locale) =>
      switch (locale?.languageCode) {
        'en' => 'English',
        'zh' => '中文',
        _ => context.l10n.setLanguageSystem,
      };

  Future<void> _editLanguage(
    BuildContext context,
    WidgetRef ref,
    Locale? current,
  ) async {
    final options = <({String label, Locale? locale})>[
      (label: context.l10n.setLanguageSystem, locale: null),
      (label: 'English', locale: const Locale('en')),
      (label: '中文', locale: const Locale('zh')),
    ];
    final choice = await showDialog<({bool chosen, Locale? locale})>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(context.l10n.setLanguage),
        children: [
          for (final opt in options)
            ListTile(
              title: Text(opt.label),
              trailing: current?.languageCode == opt.locale?.languageCode
                  ? const Icon(Icons.check)
                  : null,
              onTap: () =>
                  Navigator.pop(context, (chosen: true, locale: opt.locale)),
            ),
        ],
      ),
    );
    if (choice != null && choice.chosen) {
      await ref.read(localePreferenceProvider.notifier).set(choice.locale);
    }
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
        title: Text(context.l10n.setSalesTaxRate),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            suffixText: '%',
            labelText: context.l10n.setRate,
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.commonSave),
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
    final l10n = context.l10n;
    final result = await ref.read(printServiceProvider).printTestPage();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          result.when(
            ok: (_) => l10n.setTestPageSent,
            err: (e) => l10n.setTestPrintFailed(e.message),
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
          title: Text(context.l10n.setNetworkPrinter),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: hostController,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: context.l10n.setPrinterIp,
                  helperText: context.l10n.setPrinterIpHelper,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: portController,
                decoration: InputDecoration(labelText: context.l10n.setPort),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              SegmentedButton<int>(
                segments: [
                  ButtonSegment(
                    value: domain.EscPos.width58mm,
                    label: Text(context.l10n.setPaper58),
                  ),
                  ButtonSegment(
                    value: domain.EscPos.width80mm,
                    label: Text(context.l10n.setPaper80),
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
              child: Text(context.l10n.commonCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(context.l10n.commonSave),
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
            child: Text(context.l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.commonSave),
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
          title: Text(
            existing == null
                ? context.l10n.setNewTable
                : context.l10n.setEditTable,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: context.l10n.setTableLabelHint,
                ),
              ),
              if (existing != null)
                SwitchListTile(
                  title: Text(context.l10n.setActive),
                  value: isActive,
                  onChanged: (v) => setState(() => isActive = v),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(context.l10n.commonCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(context.l10n.commonSave),
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
      domain.PrintJobKind.kitchenTicket => context.l10n.setJobKitchenTicket,
      domain.PrintJobKind.customerReceipt => context.l10n.setJobCustomerReceipt,
      domain.PrintJobKind.testPage => context.l10n.setJobTestPage,
    };
    final (icon, statusLabel) = switch (job.status) {
      domain.PrintJobStatus.queued => (
        Icons.schedule,
        context.l10n.setJobQueued,
      ),
      domain.PrintJobStatus.printing => (
        Icons.print,
        context.l10n.setJobPrinting,
      ),
      domain.PrintJobStatus.done => (
        Icons.check_circle_outline,
        context.l10n.setJobPrinted,
      ),
      domain.PrintJobStatus.failed => (
        Icons.error_outline,
        context.l10n.setJobFailed,
      ),
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
            ? context.l10n.setJobStatusError(statusLabel, job.lastError!)
            : statusLabel,
      ),
      trailing: failed
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: context.l10n.setRetry,
                  onPressed: () =>
                      ref.read(printServiceProvider).retryJob(job.id),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: context.l10n.setDiscard,
                  onPressed: () =>
                      ref.read(printJobRepositoryProvider).deleteJob(job.id),
                ),
              ],
            )
          : null,
    );
  }
}

/// Optional cloud sync to the restaurant's own Supabase. Off by default;
/// the POS works fully offline without it.
class _CloudSyncSection extends ConsumerStatefulWidget {
  const _CloudSyncSection();

  @override
  ConsumerState<_CloudSyncSection> createState() => _CloudSyncSectionState();
}

class _CloudSyncSectionState extends ConsumerState<_CloudSyncSection> {
  bool _busy = false;
  String? _message;

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(syncSettingsProvider);
    final config = settings.config;
    final lastAt = settings.lastSyncedAt;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.setCloudSync,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        ListTile(
          leading: const Icon(Icons.cloud_outlined),
          title: Text(
            config.isConfigured
                ? context.l10n.setCloudBackingUp
                : context.l10n.setCloudNotConfigured,
          ),
          subtitle: Text(
            config.isConfigured
                ? context.l10n.setCloudConfiguredSubtitle(config.url!)
                : context.l10n.setCloudNotConfiguredSubtitle,
          ),
          isThreeLine: config.isConfigured,
          trailing: TextButton(
            onPressed: _busy ? null : () => _editCredentials(context, config),
            child: Text(
              config.isConfigured
                  ? context.l10n.commonEdit
                  : context.l10n.setSetUp,
            ),
          ),
        ),
        if (config.isConfigured) ...[
          ListTile(
            leading: Icon(
              settings.isSignedIn ? Icons.verified_user : Icons.lock_outline,
            ),
            title: Text(
              settings.isSignedIn
                  ? context.l10n.setSignedInAs(settings.restaurantEmail ?? '')
                  : context.l10n.setSignInRequired,
            ),
            subtitle: Text(
              settings.isSignedIn
                  ? context.l10n.setSignedInSubtitle
                  : context.l10n.setSignInRequiredSubtitle,
            ),
            trailing: TextButton(
              onPressed: _busy
                  ? null
                  : settings.isSignedIn
                  ? _signOut
                  : () => _signIn(context, config),
              child: Text(
                settings.isSignedIn
                    ? context.l10n.setSignOut
                    : context.l10n.setSignIn,
              ),
            ),
          ),
          if (lastAt != null)
            Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 8),
              child: Text(
                context.l10n.setLastSynced(_dateTimeFormat.format(lastAt)),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          OverflowBar(
            spacing: 8,
            children: [
              FilledButton.tonalIcon(
                onPressed: _busy ? null : _syncNow,
                icon: _busy
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.sync),
                label: Text(context.l10n.setSyncNow),
              ),
              OutlinedButton.icon(
                onPressed: _busy ? null : _restore,
                icon: const Icon(Icons.cloud_download_outlined),
                label: Text(context.l10n.setRestoreFromCloud),
              ),
            ],
          ),
        ],
        if (_message != null)
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 8),
            child: Text(
              _message!,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
      ],
    );
  }

  Future<void> _signIn(BuildContext context, SupabaseConfig config) async {
    final email = TextEditingController();
    final password = TextEditingController();
    final l10n = context.l10n;
    try {
      final ok = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(context.l10n.setRestaurantSignIn),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(context.l10n.setSignInBody),
              const SizedBox(height: 16),
              TextField(
                controller: email,
                decoration: InputDecoration(labelText: context.l10n.setEmail),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: password,
                decoration: InputDecoration(
                  labelText: context.l10n.setPassword,
                ),
                obscureText: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(context.l10n.commonCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(context.l10n.setSignIn),
            ),
          ],
        ),
      );
      if (ok != true) return;
      setState(() {
        _busy = true;
        _message = null;
      });
      final auth = SupabaseAuth(url: config.url!, anonKey: config.anonKey!);
      final session = await auth.signInWithPassword(
        email: email.text.trim(),
        password: password.text,
      );
      await ref
          .read(syncSettingsProvider)
          .saveRestaurantSession(
            email: email.text.trim(),
            refreshToken: session.refreshToken,
          );
      ref.invalidate(syncSettingsProvider);
      ref.invalidate(supabaseAuthProvider);
      if (mounted) {
        setState(() {
          _busy = false;
          _message = l10n.setSignedInMsg;
        });
      }
    } on Object catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _message = l10n.setSignInFailed('$e');
        });
      }
    } finally {
      email.dispose();
      password.dispose();
    }
  }

  Future<void> _signOut() async {
    final l10n = context.l10n;
    await ref.read(syncSettingsProvider).clearRestaurantSession();
    ref.invalidate(syncSettingsProvider);
    ref.invalidate(supabaseAuthProvider);
    setState(() => _message = l10n.setSignedOutMsg);
  }

  Future<void> _syncNow() async {
    final l10n = context.l10n;
    setState(() {
      _busy = true;
      _message = null;
    });
    final outcome = await ref.read(syncServiceProvider).syncNow();
    if (!mounted) return;
    setState(() {
      _busy = false;
      _message = outcome.ok
          ? l10n.setSyncedMsg(outcome.pulled, outcome.pushed)
          : l10n.setSyncFailed('${outcome.error}');
    });
  }

  Future<void> _restore() async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.setRestoreTitle),
        content: Text(context.l10n.setRestoreBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.setRestore),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() {
      _busy = true;
      _message = null;
    });
    final outcome = await ref.read(syncServiceProvider).restoreFromCloud();
    if (!mounted) return;
    setState(() {
      _busy = false;
      _message = outcome.ok
          ? l10n.setRestoredMsg(outcome.pulled)
          : l10n.setRestoreFailed('${outcome.error}');
    });
  }

  Future<void> _editCredentials(
    BuildContext context,
    SupabaseConfig current,
  ) async {
    final urlController = TextEditingController(text: current.url ?? '');
    final keyController = TextEditingController(text: current.anonKey ?? '');
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.setYourSupabaseProject),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(context.l10n.setSupabaseBody),
            const SizedBox(height: 16),
            TextField(
              controller: urlController,
              decoration: InputDecoration(
                labelText: context.l10n.setProjectUrl,
                hintText: 'https://xxxx.supabase.co',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: keyController,
              decoration: InputDecoration(labelText: context.l10n.setAnonKey),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.commonSave),
          ),
        ],
      ),
    );
    if (saved == true) {
      await ref
          .read(syncSettingsProvider)
          .setConfig(
            SupabaseConfig(
              url: urlController.text,
              anonKey: keyController.text,
            ),
          );
      ref.invalidate(syncSettingsProvider);
      if (mounted) setState(() => _message = null);
    }
  }
}
