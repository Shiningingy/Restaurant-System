import 'dart:async';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:restaurant_domain/restaurant_domain.dart' as domain;

import '../../../core/db/database.dart';
import '../../../core/l10n_ext.dart';
import '../../../core/settings/providers.dart';
import '../../../core/settings/settings_repository.dart';
import '../../../core/supabase_auth.dart';
import '../../../l10n/app_localizations.dart';
import '../../customer_display/application/customer_display.dart';
import '../../customer_display/data/promo_image_store.dart';
import '../../help/presentation/help_screen.dart';
import '../../printing/application/providers.dart';
import '../../printing/data/printer_discovery.dart';
import '../../printing/drivers/windows_printers.dart';
import '../../sync/application/providers.dart';
import '../../sync/data/sync_settings.dart';
import 'storefront_qr_dialog.dart';

final _dateTimeFormat = DateFormat('yyyy-MM-dd HH:mm');

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final taxRateBp = ref.watch(taxRateBpProvider);
    final tables = ref.watch(tablesProvider).value ?? const [];
    final printers = ref.watch(printersProvider);
    final receiptConfig = ref.watch(receiptConfigProvider);
    final printJobs = ref.watch(printJobsProvider).value ?? const [];
    final localePref = ref.watch(localePreferenceProvider);
    final nameDisplay = ref.watch(nameDisplayProvider);

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
          ListTile(
            leading: const Icon(Icons.menu_book_outlined),
            title: Text(context.l10n.setHelp),
            subtitle: Text(context.l10n.setHelpSubtitle),
            onTap: () => openHelp(context),
          ),
          const Divider(height: 32),
          Text(
            context.l10n.setSecondNameSection,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 4),
            child: Text(
              context.l10n.setSecondNameHint,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          SwitchListTile(
            title: Text(context.l10n.setSecondNameOrderScreen),
            value: nameDisplay.orderScreen,
            onChanged: (v) => ref
                .read(nameDisplayProvider.notifier)
                .save(nameDisplay.copyWith(orderScreen: v)),
          ),
          SwitchListTile(
            title: Text(context.l10n.setSecondNameKitchen),
            value: nameDisplay.kitchenTicket,
            onChanged: (v) => ref
                .read(nameDisplayProvider.notifier)
                .save(nameDisplay.copyWith(kitchenTicket: v)),
          ),
          SwitchListTile(
            title: Text(context.l10n.setSecondNameReceipt),
            value: nameDisplay.receipt,
            onChanged: (v) => ref
                .read(nameDisplayProvider.notifier)
                .save(nameDisplay.copyWith(receipt: v)),
          ),
          ListTile(
            leading: const Icon(Icons.translate_outlined),
            title: Text(context.l10n.setSecondNameLanguage),
            subtitle: Text(context.l10n.setSecondNameLanguageHint),
            trailing: Text(
              _secondNameLangLabel(
                context,
                ref.watch(secondNameLanguageProvider),
              ),
            ),
            onTap: () => _editSecondNameLanguage(
              context,
              ref,
              ref.read(secondNameLanguageProvider),
            ),
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
          _CheckoutPricingSection(pricing: ref.watch(checkoutPricingProvider)),
          const Divider(height: 32),
          _OnlineOrderingSection(
            settings: ref.watch(onlineOrderSettingsProvider),
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
          Text(
            context.l10n.setPrinting,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          for (final role in PrinterRole.values)
            ListTile(
              leading: Icon(
                role == PrinterRole.kitchen
                    ? Icons.soup_kitchen_outlined
                    : Icons.receipt_long_outlined,
              ),
              title: Text(
                role == PrinterRole.kitchen
                    ? context.l10n.setPrinterKitchen
                    : context.l10n.setPrinterReceipt,
              ),
              subtitle: Text(_printerSummary(context, printers[role]!)),
              trailing: printers[role]!.isConfigured
                  ? IconButton(
                      icon: const Icon(Icons.print_outlined),
                      tooltip: context.l10n.setTestPrint,
                      onPressed: () => _testPrint(
                        context,
                        ref,
                        role == PrinterRole.kitchen
                            ? domain.PrintJobKind.kitchenTicket
                            : domain.PrintJobKind.testPage,
                      ),
                    )
                  : null,
              onTap: () =>
                  _editPrinterConfig(context, ref, role, printers[role]!),
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
          const Divider(height: 32),
          Text(
            context.l10n.setCustomerDisplay,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          ListTile(
            leading: const Icon(Icons.view_carousel_outlined),
            title: Text(context.l10n.setDisplayMode),
            subtitle: Text(
              _displayModeLabel(
                context,
                ref.watch(customerDisplayModeProvider),
              ),
            ),
            onTap: () => _editDisplayMode(context, ref),
          ),
          ListTile(
            leading: const Icon(Icons.tv_outlined),
            title: Text(context.l10n.setOpenCustomerDisplay),
            subtitle: Text(context.l10n.setCustomerDisplayHint),
            onTap: () => ref
                .read(customerDisplayProvider)
                .open(
                  businessName: receiptConfig.businessName,
                  mode: ref.read(customerDisplayModeProvider),
                  promoLines: ref.read(displayPromoProvider),
                  promoImages: ref.read(displayPromoImagesProvider),
                ),
          ),
          ListTile(
            leading: const Icon(Icons.campaign_outlined),
            title: Text(context.l10n.setDisplayPromo),
            subtitle: Text(
              ref.watch(displayPromoProvider).isEmpty
                  ? context.l10n.setDisplayPromoNone
                  : ref.watch(displayPromoProvider).join(' · '),
            ),
            onTap: () => _editPromo(context, ref),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: Text(context.l10n.setDisplayPromoPhotos),
            subtitle: Text(
              ref.watch(displayPromoImagesProvider).isEmpty
                  ? context.l10n.setDisplayPromoPhotosNone
                  : context.l10n.setDisplayPromoPhotosCount(
                      ref.watch(displayPromoImagesProvider).length,
                    ),
            ),
            onTap: () => _editPromoPhotos(context, ref),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.point_of_sale_outlined),
            title: Text(context.l10n.setKioskPayHere),
            subtitle: Text(context.l10n.setKioskPayHereHint),
            value: ref.watch(kioskPayHereProvider),
            onChanged: (v) => ref.read(kioskPayHereProvider.notifier).set(v),
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

  String _secondNameLangLabel(BuildContext context, String? code) =>
      switch (code) {
        'en' => 'English',
        'zh' => '中文',
        _ => context.l10n.setSecondNameLanguageNone,
      };

  Future<void> _editSecondNameLanguage(
    BuildContext context,
    WidgetRef ref,
    String? current,
  ) async {
    final options = <({String label, String? code})>[
      (label: context.l10n.setSecondNameLanguageNone, code: null),
      (label: 'English', code: 'en'),
      (label: '中文', code: 'zh'),
    ];
    final choice = await showDialog<({bool chosen, String? code})>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(context.l10n.setSecondNameLanguage),
        children: [
          for (final opt in options)
            ListTile(
              title: Text(opt.label),
              trailing: current == opt.code ? const Icon(Icons.check) : null,
              onTap: () =>
                  Navigator.pop(context, (chosen: true, code: opt.code)),
            ),
        ],
      ),
    );
    if (choice != null && choice.chosen) {
      await ref.read(secondNameLanguageProvider.notifier).set(choice.code);
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

  Future<void> _editPromo(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController(
      text: ref.read(displayPromoProvider).join('\n'),
    );
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.setDisplayPromo),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 6,
          decoration: InputDecoration(
            helperText: context.l10n.setDisplayPromoHint,
          ),
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
      final lines = controller.text
          .split('\n')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      await ref.read(displayPromoProvider.notifier).set(lines);
    }
  }

  String _displayModeLabel(BuildContext context, CustomerDisplayMode mode) =>
      switch (mode) {
        CustomerDisplayMode.passive => context.l10n.setDisplayModePassive,
        CustomerDisplayMode.kiosk => context.l10n.setDisplayModeKiosk,
        CustomerDisplayMode.hybrid => context.l10n.setDisplayModeHybrid,
      };

  String _displayModeDesc(BuildContext context, CustomerDisplayMode mode) =>
      switch (mode) {
        CustomerDisplayMode.passive => context.l10n.setDisplayModePassiveDesc,
        CustomerDisplayMode.kiosk => context.l10n.setDisplayModeKioskDesc,
        CustomerDisplayMode.hybrid => context.l10n.setDisplayModeHybridDesc,
      };

  /// Picks how the customer-facing screen behaves. If the display is already
  /// open, the new mode is pushed to it live.
  Future<void> _editDisplayMode(BuildContext context, WidgetRef ref) async {
    final current = ref.read(customerDisplayModeProvider);
    final picked = await showDialog<CustomerDisplayMode>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(context.l10n.setDisplayMode),
        children: [
          for (final mode in CustomerDisplayMode.values)
            RadioListTile<CustomerDisplayMode>(
              value: mode,
              // ignore: deprecated_member_use
              groupValue: current,
              // ignore: deprecated_member_use
              onChanged: (m) => Navigator.pop(context, m),
              title: Text(_displayModeLabel(context, mode)),
              subtitle: Text(_displayModeDesc(context, mode)),
            ),
        ],
      ),
    );
    if (picked == null) return;
    await ref.read(customerDisplayModeProvider.notifier).set(picked);
    // Reflect the change on an already-open display without reopening it.
    final display = ref.read(customerDisplayProvider);
    if (display.isOpen) await display.pushMode(picked);
  }

  /// Manages the customer-display promo slideshow: shows the current photos,
  /// with actions to add more (file picker) or clear them. Picked files are
  /// copied into app storage so the paths stay valid.
  Future<void> _editPromoPhotos(BuildContext context, WidgetRef ref) async {
    final action = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(context.l10n.setDisplayPromoPhotos),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 'add'),
            child: ListTile(
              leading: const Icon(Icons.add_photo_alternate_outlined),
              title: Text(context.l10n.setDisplayPromoPhotosAdd),
            ),
          ),
          if (ref.read(displayPromoImagesProvider).isNotEmpty)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, 'clear'),
              child: ListTile(
                leading: const Icon(Icons.delete_outline),
                title: Text(context.l10n.setDisplayPromoPhotosClear),
              ),
            ),
        ],
      ),
    );
    if (action == 'clear') {
      final store = PromoImageStore();
      for (final path in ref.read(displayPromoImagesProvider)) {
        await store.delete(path);
      }
      await ref.read(displayPromoImagesProvider.notifier).set(const []);
      return;
    }
    if (action != 'add') return;
    const group = XTypeGroup(
      label: 'images',
      extensions: ['jpg', 'jpeg', 'png', 'webp', 'gif', 'bmp'],
    );
    final files = await openFiles(acceptedTypeGroups: [group]);
    if (files.isEmpty) return;
    final store = PromoImageStore();
    final added = [for (final f in files) await store.import(f.path)];
    await ref.read(displayPromoImagesProvider.notifier).set([
      ...ref.read(displayPromoImagesProvider),
      ...added,
    ]);
  }

  String _printerSummary(BuildContext context, PrinterConfig cfg) {
    if (!cfg.isConfigured) return context.l10n.setPrinterNotConfigured;
    final width = cfg.paperWidthChars == domain.EscPos.width58mm ? '58' : '80';
    return cfg.transport == domain.PrinterTransport.network
        ? context.l10n.setPrinterConfigured(cfg.host!, cfg.port, width)
        : context.l10n.setPrinterConfiguredUsb(cfg.windowsPrinterName!, width);
  }

  Future<void> _testPrint(
    BuildContext context,
    WidgetRef ref,
    domain.PrintJobKind kind,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    final result = await ref
        .read(printServiceProvider)
        .printTestPage(kind: kind);
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

  Future<void> _editPrinterConfig(
    BuildContext context,
    WidgetRef ref,
    PrinterRole role,
    PrinterConfig current,
  ) async {
    final result = await showDialog<PrinterConfig>(
      context: context,
      builder: (context) => _PrinterConfigDialog(role: role, current: current),
    );
    if (result != null) {
      await ref.read(printersProvider.notifier).save(role, result);
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

/// Configures one printer (kitchen or receipt): connection (network host:port
/// or a Windows-installed printer), paper width, text encoding, and — for the
/// receipt printer — whether to kick the cash drawer. Returns the chosen
/// [PrinterConfig] on save, or null if cancelled.
class _PrinterConfigDialog extends StatefulWidget {
  final PrinterRole role;
  final PrinterConfig current;

  const _PrinterConfigDialog({required this.role, required this.current});

  @override
  State<_PrinterConfigDialog> createState() => _PrinterConfigDialogState();
}

class _PrinterConfigDialogState extends State<_PrinterConfigDialog> {
  late domain.PrinterTransport _transport;
  late final TextEditingController _host;
  late final TextEditingController _port;
  late int _widthChars;
  late domain.TicketCharset _charset;
  late bool _openDrawer;
  String? _windowsPrinter;
  List<String> _windowsPrinters = const [];

  final List<DiscoveredPrinter> _found = [];
  StreamSubscription<DiscoveredPrinter>? _scan;
  bool _scanning = false;

  @override
  void initState() {
    super.initState();
    final c = widget.current;
    _transport = c.transport == domain.PrinterTransport.usb
        ? domain.PrinterTransport.usb
        : domain.PrinterTransport.network;
    _host = TextEditingController(text: c.host ?? '');
    _port = TextEditingController(text: c.port.toString());
    _widthChars = c.paperWidthChars;
    _charset = c.charset;
    _openDrawer = c.openDrawer;
    _windowsPrinter = c.windowsPrinterName;
    _loadWindowsPrinters();
  }

  /// Lists Windows printers; keeps the saved name selectable even if listing
  /// is empty (e.g. the printer is offline, or we're not on Windows).
  void _loadWindowsPrinters() {
    final list = WindowsPrinters.list();
    final saved = _windowsPrinter;
    setState(() {
      _windowsPrinters =
          (saved != null && saved.isNotEmpty && !list.contains(saved))
          ? [saved, ...list]
          : list;
    });
  }

  @override
  void dispose() {
    _scan?.cancel();
    _host.dispose();
    _port.dispose();
    super.dispose();
  }

  void _toggleScan() {
    if (_scanning) {
      _scan?.cancel();
      setState(() => _scanning = false);
      return;
    }
    setState(() {
      _scanning = true;
      _found.clear();
    });
    _scan = PrinterDiscovery().discover().listen(
      (printer) {
        if (!_found.contains(printer)) setState(() => _found.add(printer));
      },
      onDone: () {
        if (mounted) setState(() => _scanning = false);
      },
      onError: (_) {
        if (mounted) setState(() => _scanning = false);
      },
    );
  }

  void _pick(DiscoveredPrinter printer) {
    setState(() {
      _host.text = printer.host;
      _port.text = printer.port.toString();
    });
  }

  void _save() {
    Navigator.pop(
      context,
      PrinterConfig(
        transport: _transport,
        host: _host.text.trim(),
        port:
            int.tryParse(_port.text.trim()) ??
            SettingsRepository.defaultPrinterPort,
        windowsPrinterName: _windowsPrinter,
        paperWidthChars: _widthChars,
        charset: _charset,
        openDrawer: _openDrawer,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isNetwork = _transport == domain.PrinterTransport.network;
    return AlertDialog(
      title: Text(
        widget.role == PrinterRole.kitchen
            ? l10n.setPrinterKitchen
            : l10n.setPrinterReceipt,
      ),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SegmentedButton<domain.PrinterTransport>(
                segments: [
                  ButtonSegment(
                    value: domain.PrinterTransport.network,
                    label: Text(l10n.setTransportNetwork),
                    icon: const Icon(Icons.lan_outlined),
                  ),
                  ButtonSegment(
                    value: domain.PrinterTransport.usb,
                    label: Text(l10n.setTransportWindows),
                    icon: const Icon(Icons.usb),
                  ),
                ],
                selected: {_transport},
                onSelectionChanged: (s) => setState(() => _transport = s.first),
              ),
              const SizedBox(height: 16),
              if (isNetwork)
                ..._networkFields(l10n)
              else
                ..._windowsFields(l10n),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  l10n.setPaperWidth,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              const SizedBox(height: 4),
              SegmentedButton<int>(
                segments: [
                  ButtonSegment(
                    value: domain.EscPos.width58mm,
                    label: Text(l10n.setPaper58),
                  ),
                  ButtonSegment(
                    value: domain.EscPos.width80mm,
                    label: Text(l10n.setPaper80),
                  ),
                ],
                selected: {_widthChars},
                onSelectionChanged: (s) =>
                    setState(() => _widthChars = s.first),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  l10n.setCharset,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              const SizedBox(height: 4),
              SegmentedButton<domain.TicketCharset>(
                segments: [
                  ButtonSegment(
                    value: domain.TicketCharset.western,
                    label: Text(l10n.setCharsetWestern),
                  ),
                  ButtonSegment(
                    value: domain.TicketCharset.chinese,
                    label: Text(l10n.setCharsetChinese),
                  ),
                ],
                selected: {_charset},
                onSelectionChanged: (s) => setState(() => _charset = s.first),
              ),
              if (widget.role == PrinterRole.receipt)
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.setOpenDrawer),
                  value: _openDrawer,
                  onChanged: (v) => setState(() => _openDrawer = v),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(onPressed: _save, child: Text(l10n.commonSave)),
      ],
    );
  }

  List<Widget> _networkFields(AppLocalizations l10n) => [
    OutlinedButton.icon(
      onPressed: _toggleScan,
      icon: _scanning
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.wifi_find_outlined),
      label: Text(_scanning ? l10n.setPrinterSearching : l10n.setPrinterSearch),
    ),
    if (_found.isNotEmpty || _scanning) ...[
      const SizedBox(height: 8),
      ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 160),
        child: _found.isEmpty
            ? Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  l10n.setPrinterSearching,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              )
            : ListView(
                shrinkWrap: true,
                children: [
                  for (final p in _found)
                    ListTile(
                      dense: true,
                      leading: const Icon(Icons.print_outlined),
                      title: Text('${p.host}:${p.port}'),
                      onTap: () => _pick(p),
                    ),
                ],
              ),
      ),
    ],
    const SizedBox(height: 8),
    TextField(
      controller: _host,
      decoration: InputDecoration(
        labelText: l10n.setPrinterIp,
        helperText: l10n.setPrinterIpHelper,
      ),
    ),
    const SizedBox(height: 8),
    TextField(
      controller: _port,
      decoration: InputDecoration(labelText: l10n.setPort),
      keyboardType: TextInputType.number,
    ),
  ];

  List<Widget> _windowsFields(AppLocalizations l10n) => [
    Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<String>(
            initialValue:
                (_windowsPrinter != null &&
                    _windowsPrinters.contains(_windowsPrinter))
                ? _windowsPrinter
                : null,
            isExpanded: true,
            decoration: InputDecoration(labelText: l10n.setWindowsPrinter),
            items: [
              for (final name in _windowsPrinters)
                DropdownMenuItem(
                  value: name,
                  child: Text(name, overflow: TextOverflow.ellipsis),
                ),
            ],
            onChanged: (v) => setState(() => _windowsPrinter = v),
          ),
        ),
        IconButton(
          tooltip: l10n.setRefresh,
          onPressed: _loadWindowsPrinters,
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    if (_windowsPrinters.isEmpty)
      Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(
          l10n.setWindowsPrinterNone,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ),
  ];
}

/// Checkout pricing: a service fee on every order, the discount presets staff
/// can pick, and the cap they may discount without a manager's PIN.
class _CheckoutPricingSection extends ConsumerWidget {
  final CheckoutPricing pricing;

  const _CheckoutPricingSection({required this.pricing});

  static String _pct(int bp) =>
      bp % 100 == 0 ? '${bp ~/ 100}%' : '${(bp / 100).toStringAsFixed(2)}%';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.setCheckout,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        ListTile(
          leading: const Icon(Icons.room_service_outlined),
          title: Text(context.l10n.setServiceFee),
          subtitle: Text(context.l10n.setServiceFeeHint),
          trailing: Text(
            _pct(pricing.serviceFeeBp),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          onTap: () => _editPercent(
            context,
            title: context.l10n.setServiceFee,
            currentBp: pricing.serviceFeeBp,
            onPicked: (bp) =>
                ref.read(checkoutPricingProvider.notifier).setServiceFeeBp(bp),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.local_offer_outlined),
          title: Text(context.l10n.setDiscountPresets),
          subtitle: Text(
            pricing.discountPresetsBp.isEmpty
                ? context.l10n.setDiscountPresetsNone
                : pricing.discountPresetsBp.map(_pct).join(', '),
          ),
          onTap: () => _editPresets(context, ref),
        ),
        ListTile(
          leading: const Icon(Icons.shield_outlined),
          title: Text(context.l10n.setDiscountThreshold),
          subtitle: Text(context.l10n.setDiscountThresholdHint),
          trailing: Text(
            _pct(pricing.discountThresholdBp),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          onTap: () => _editPercent(
            context,
            title: context.l10n.setDiscountThreshold,
            currentBp: pricing.discountThresholdBp,
            onPicked: (bp) => ref
                .read(checkoutPricingProvider.notifier)
                .setDiscountThresholdBp(bp),
          ),
        ),
      ],
    );
  }

  Future<void> _editPercent(
    BuildContext context, {
    required String title,
    required int currentBp,
    required void Function(int bp) onPicked,
  }) async {
    final controller = TextEditingController(
      text: currentBp == 0 ? '' : (currentBp / 100).toString(),
    );
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(suffixText: '%'),
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
    if (ok == true) {
      final pct = double.tryParse(controller.text.trim()) ?? 0;
      onPicked((pct * 100).round().clamp(0, 10000));
    }
  }

  Future<void> _editPresets(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController(
      text: pricing.discountPresetsBp.map((bp) => bp / 100).join(', '),
    );
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.setDiscountPresets),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            helperText: context.l10n.setDiscountPresetsHint,
          ),
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
    if (ok == true) {
      final presets = controller.text
          .split(RegExp(r'[,\s]+'))
          .map((s) => double.tryParse(s.trim()))
          .whereType<double>()
          .map((pct) => (pct * 100).round())
          .where((bp) => bp > 0 && bp <= 10000)
          .toList();
      await ref
          .read(checkoutPricingProvider.notifier)
          .setDiscountPresetsBp(presets);
    }
  }
}

/// Online-ordering preferences: minimum pickup lead time (published with the
/// menu so customers can't ask for an impossible time) and a new-order chime.
class _OnlineOrderingSection extends ConsumerWidget {
  final OnlineOrderSettings settings;

  const _OnlineOrderingSection({required this.settings});

  static const _leadChoices = [0, 5, 10, 15, 20, 30, 45, 60];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.setOnlineOrdering,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        ListTile(
          leading: const Icon(Icons.timer_outlined),
          title: Text(context.l10n.setPickupLead),
          subtitle: Text(context.l10n.setPickupLeadSubtitle),
          trailing: Text(
            context.l10n.setPickupLeadValue(settings.pickupLeadMinutes),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          onTap: () => _editLead(context, ref),
        ),
        SwitchListTile(
          secondary: const Icon(Icons.notifications_active_outlined),
          title: Text(context.l10n.setNewOrderSound),
          value: settings.newOrderSound,
          onChanged: (v) => ref
              .read(onlineOrderSettingsProvider.notifier)
              .setNewOrderSound(v),
        ),
      ],
    );
  }

  Future<void> _editLead(BuildContext context, WidgetRef ref) async {
    final picked = await showDialog<int>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(context.l10n.setPickupLead),
        children: [
          for (final m in _leadChoices)
            ListTile(
              title: Text(context.l10n.setPickupLeadValue(m)),
              trailing: m == settings.pickupLeadMinutes
                  ? const Icon(Icons.check)
                  : null,
              onTap: () => Navigator.pop(context, m),
            ),
        ],
      ),
    );
    if (picked != null) {
      await ref
          .read(onlineOrderSettingsProvider.notifier)
          .setPickupLead(picked);
    }
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
              OutlinedButton.icon(
                onPressed: () => showStorefrontConnectQr(
                  context,
                  url: config.url!,
                  anonKey: config.anonKey!,
                  name: ref.read(receiptConfigProvider).businessName,
                ),
                icon: const Icon(Icons.qr_code_2),
                label: Text(context.l10n.setCustomerQr),
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
