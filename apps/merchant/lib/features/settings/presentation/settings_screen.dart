import 'dart:async';
import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:restaurant_domain/restaurant_domain.dart' as domain;
import 'package:restaurant_ui/restaurant_ui.dart';

import '../../../core/db/database.dart';
import '../../../core/db/db_backup.dart';
import '../../../core/l10n_ext.dart';
import '../../../core/providers.dart';
import '../../../core/settings/brand_logo_store.dart';
import '../../../core/settings/providers.dart';
import '../../../core/settings/settings_repository.dart';
import '../../../core/supabase_auth.dart';
import '../../../core/window/window_control.dart';
import '../../../l10n/app_localizations.dart';
import '../../customer_display/application/customer_display.dart';
import '../../customer_display/data/promo_image_store.dart';
import '../../help/presentation/help_screen.dart';
import '../../printing/application/providers.dart';
import '../../printing/data/printer_discovery.dart';
import '../../printing/drivers/windows_printers.dart';
import '../../sync/application/providers.dart';
import '../../sync/application/sync_service.dart';
import '../../sync/data/sync_settings.dart';
import 'storefront_qr_dialog.dart';

final _dateTimeFormat = DateFormat('yyyy-MM-dd HH:mm');

/// Outcome of the pre-sync confirm dialog.
enum _SyncChoice { cancel, sync, restore }

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    // A clean hub: each tile opens a focused sub-page with just that group's
    // settings, instead of one long scrolling page.
    return Scaffold(
      appBar: AppBar(title: Text(l10n.navSettings)),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          // Store identity first — the shop name + logos.
          _hubTile(
            context,
            Icons.storefront_outlined,
            l10n.setBranding,
            _brandingBody,
          ),
          _hubTile(
            context,
            Icons.translate_outlined,
            l10n.setLanguage,
            _languageBody,
          ),
          _hubTile(context, Icons.percent_outlined, l10n.setTax, _taxBody),
          _hubTile(
            context,
            Icons.language_outlined,
            l10n.setOnlineOrdering,
            _onlineBody,
          ),
          _hubTile(
            context,
            Icons.point_of_sale_outlined,
            l10n.setPayments,
            _paymentsBody,
          ),
          _hubTile(
            context,
            Icons.print_outlined,
            l10n.setPrinting,
            _printingBody,
          ),
          _hubTile(
            context,
            Icons.tv_outlined,
            l10n.setCustomerDisplay,
            _displayBody,
          ),
          _hubTile(
            context,
            Icons.table_restaurant_outlined,
            l10n.setTables,
            _tablesBody,
          ),
          _hubTile(
            context,
            Icons.cloud_outlined,
            l10n.setCloudSync,
            _cloudBody,
          ),
          // The user guide, opened directly (not a sub-page).
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: ListTile(
              leading: const Icon(Icons.menu_book_outlined),
              title: Text(l10n.setHelp),
              subtitle: Text(l10n.setHelpSubtitle),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => openHelp(context),
            ),
          ),
        ],
      ),
    );
  }

  /// One hub entry → pushes a focused sub-page that renders [body].
  Widget _hubTile(
    BuildContext context,
    IconData icon,
    String title,
    List<Widget> Function(BuildContext, WidgetRef) body,
  ) => Card(
    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    child: ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => _SettingsDetailPage(title: title, body: body),
        ),
      ),
    ),
  );

  // ── Sub-page bodies: each returns just one group's controls. ──

  List<Widget> _languageBody(BuildContext context, WidgetRef ref) {
    final localePref = ref.watch(localePreferenceProvider);
    final nameDisplay = ref.watch(nameDisplayProvider);
    return [
      ListTile(
        leading: const Icon(Icons.translate_outlined),
        title: Text(context.l10n.setLanguage),
        subtitle: Text(_languageLabel(context, localePref)),
        onTap: () => _editLanguage(context, ref, localePref),
      ),
      const Divider(height: 32),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: Text(
          context.l10n.setSecondNameSection,
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
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
          _secondNameLangLabel(context, ref.watch(secondNameLanguageProvider)),
        ),
        onTap: () => _editSecondNameLanguage(
          context,
          ref,
          ref.read(secondNameLanguageProvider),
        ),
      ),
    ];
  }

  List<Widget> _taxBody(BuildContext context, WidgetRef ref) {
    final taxRateBp = ref.watch(taxRateBpProvider);
    return [
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
    ];
  }

  List<Widget> _onlineBody(BuildContext context, WidgetRef ref) => [
    _OnlineOrderingSection(settings: ref.watch(onlineOrderSettingsProvider)),
  ];

  List<Widget> _paymentsBody(BuildContext context, WidgetRef ref) => [
    ListTile(
      leading: const Icon(Icons.point_of_sale_outlined),
      title: Text(context.l10n.setCardTerminalManual),
      subtitle: Text(context.l10n.setCardTerminalManualSubtitle),
    ),
  ];

  List<Widget> _printingBody(BuildContext context, WidgetRef ref) {
    final printers = ref.watch(printersProvider);
    final receiptConfig = ref.watch(receiptConfigProvider);
    final printJobs = ref.watch(printJobsProvider).value ?? const [];
    return [
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
          onTap: () => _editPrinterConfig(context, ref, role, printers[role]!),
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
            await ref.read(receiptConfigProvider.notifier).setFooter(footer);
          }
        },
      ),
      if (printJobs.isNotEmpty) ...[
        const Divider(height: 32),
        Padding(
          padding: const EdgeInsets.only(left: 16, top: 8),
          child: Text(
            context.l10n.setPrintQueue,
            style: Theme.of(context).textTheme.labelLarge,
          ),
        ),
        for (final job in printJobs) _PrintJobTile(job: job),
      ],
    ];
  }

  List<Widget> _displayBody(BuildContext context, WidgetRef ref) {
    final receiptConfig = ref.watch(receiptConfigProvider);
    return [
      ListTile(
        leading: const Icon(Icons.view_carousel_outlined),
        title: Text(context.l10n.setDisplayMode),
        subtitle: Text(
          _displayModeLabel(context, ref.watch(customerDisplayModeProvider)),
        ),
        onTap: () => _editDisplayMode(context, ref),
      ),
      ListTile(
        leading: const Icon(Icons.tv_outlined),
        title: Text(context.l10n.setOpenCustomerDisplay),
        subtitle: Text(context.l10n.setCustomerDisplayHint),
        onTap: () {
          final display = ref.read(customerDisplayProvider);
          // "Open" doubles as "show again" after the display was hidden.
          if (display.isOpen) {
            display.restore();
          } else {
            display.open(
              businessName: receiptConfig.businessName,
              mode: ref.read(customerDisplayModeProvider),
              promoLines: ref.read(displayPromoProvider),
              promoImages: ref.read(displayPromoImagesProvider),
              brandWelcome: ref
                  .read(brandLogosProvider)
                  .resolve(BrandLogoSlot.displayWelcome),
              brandOrderHeader: ref
                  .read(brandLogosProvider)
                  .resolve(BrandLogoSlot.displayOrderHeader),
              brandKioskHeader: ref
                  .read(brandLogosProvider)
                  .resolve(BrandLogoSlot.kioskHeader),
              brandKioskConfirm: ref
                  .read(brandLogosProvider)
                  .resolve(BrandLogoSlot.kioskConfirm),
            );
          }
        },
      ),
      ListTile(
        leading: const Icon(Icons.tv_off_outlined),
        title: Text(context.l10n.setDisplayHide),
        subtitle: Text(context.l10n.setDisplayHideHint),
        trailing: TextButton(
          onPressed: () => ref.read(customerDisplayProvider).close(),
          child: Text(context.l10n.setDisplayClose),
        ),
        onTap: () => ref.read(customerDisplayProvider).minimize(),
      ),
      SwitchListTile(
        secondary: const Icon(Icons.fullscreen),
        title: Text(context.l10n.setMainFullscreen),
        subtitle: Text(context.l10n.setMainFullscreenHint),
        value: ref.watch(mainFullscreenProvider),
        onChanged: (v) async {
          final state = await ref
              .read(windowControlProvider)
              .setMainFullscreen(v);
          ref.read(mainFullscreenProvider.notifier).set(state);
        },
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
    ];
  }

  List<Widget> _tablesBody(BuildContext context, WidgetRef ref) {
    final tables = ref.watch(tablesProvider).value ?? const [];
    return [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
        child: Row(
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
    ];
  }

  List<Widget> _cloudBody(BuildContext context, WidgetRef ref) => const [
    _CloudSyncSection(),
  ];

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
      await _publishPromo(ref);
      await ref.read(customerDisplayProvider).pushCurrentPromo();
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
      await _publishPromo(ref);
      await ref.read(customerDisplayProvider).pushCurrentPromo();
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
    await _publishPromo(ref);
    await ref.read(customerDisplayProvider).pushCurrentPromo();
  }

  /// The Branding page: a global default logo plus an override per placement.
  /// Each placement with none falls back to the default.
  List<Widget> _brandingBody(BuildContext context, WidgetRef ref) {
    final logos = ref.watch(brandLogosProvider);
    final receiptConfig = ref.watch(receiptConfigProvider);
    final l10n = context.l10n;
    // (slot, title, dark-background?) — the global default first.
    final rows = <(BrandLogoSlot, String, bool)>[
      (BrandLogoSlot.global, l10n.setBrandGlobal, false),
      (BrandLogoSlot.appNav, l10n.setBrandNav, false),
      (BrandLogoSlot.displayWelcome, l10n.setBrandWelcome, false),
      (BrandLogoSlot.displayOrderHeader, l10n.setBrandOrderHeader, true),
      (BrandLogoSlot.kioskHeader, l10n.setBrandKioskHeader, true),
      (BrandLogoSlot.kioskConfirm, l10n.setBrandKioskConfirm, false),
    ];
    return [
      // The shop name — shown on receipts, the customer display and kiosk.
      ListTile(
        leading: const Icon(Icons.storefront_outlined),
        title: Text(context.l10n.setBusinessName),
        subtitle: Text(
          receiptConfig.businessName.isEmpty
              ? context.l10n.setBusinessNameHint
              : receiptConfig.businessName,
        ),
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
      const Divider(height: 1),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Text(
          l10n.setBrandingHint,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ),
      for (final (slot, title, dark) in rows) ...[
        _brandLogoTile(context, ref, logos, slot, title: title, dark: dark),
        // A divider under the global default separates it from the overrides.
        if (slot == BrandLogoSlot.global) const Divider(height: 1),
      ],
    ];
  }

  /// A single logo slot: a live preview of the *resolved* logo (its own, else
  /// the default) on its representative background, plus pick / clear.
  Widget _brandLogoTile(
    BuildContext context,
    WidgetRef ref,
    BrandLogos logos,
    BrandLogoSlot slot, {
    required String title,
    required bool dark,
  }) {
    final cs = Theme.of(context).colorScheme;
    final explicit = logos.forSlot(slot); // set for this slot specifically?
    final preview = logos.resolve(slot); // what actually shows (with fallback)
    final isGlobal = slot == BrandLogoSlot.global;
    return ListTile(
      leading: Container(
        width: 52,
        height: 52,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: dark ? cs.primary : cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(10),
        ),
        child: BrandMark(
          logoPath: preview,
          size: 36,
          fallbackColor: dark ? cs.onPrimary : cs.primary,
        ),
      ),
      title: Text(title),
      subtitle: Text(
        explicit != null
            ? context.l10n.setBrandLogoSet
            : isGlobal
            ? context.l10n.setBrandGlobalHint
            : context.l10n.setBrandUsingDefault,
      ),
      trailing: explicit == null
          ? const Icon(Icons.add_photo_alternate_outlined)
          : IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: context.l10n.commonDelete,
              onPressed: () async {
                await BrandLogoStore(slot: slot.name).clear();
                await ref.read(brandLogosProvider.notifier).set(slot, null);
                await _publishBrandLogo(ref, slot);
              },
            ),
      onTap: () => _editBrandLogo(context, ref, slot),
    );
  }

  /// Picks the logo for [slot] and stores it locally.
  Future<void> _editBrandLogo(
    BuildContext context,
    WidgetRef ref,
    BrandLogoSlot slot,
  ) async {
    const group = XTypeGroup(
      label: 'images',
      extensions: ['jpg', 'jpeg', 'png', 'webp', 'gif', 'bmp'],
    );
    final file = await openFile(acceptedTypeGroups: [group]);
    if (file == null) return;
    final path = await BrandLogoStore(slot: slot.name).import(file.path);
    await ref.read(brandLogosProvider.notifier).set(slot, path);
    await _publishBrandLogo(ref, slot);
  }

  /// Uploads a logo slot to the shop's Storage bucket so other devices pick it
  /// up on sync. Best-effort: no-op when the cloud isn't set up.
  Future<void> _publishBrandLogo(WidgetRef ref, BrandLogoSlot slot) async {
    // Reflect the new logo on an already-open display right away — independent
    // of the cloud (a local-only shop should still see it update live).
    await ref.read(customerDisplayProvider).pushCurrentBrand();
    if (!ref.read(syncSettingsProvider).config.isConfigured) return;
    try {
      await ref.read(brandLogoSyncProvider(slot)).publish();
    } on Object {
      // The logo still works locally; it'll publish on the next change/sync.
    }
  }

  /// Uploads the current promo set to the shop's Storage bucket so other
  /// devices pick it up on sync. Best-effort: no-op when the cloud isn't set
  /// up, and a failure never blocks the (already-saved) local change.
  Future<void> _publishPromo(WidgetRef ref) async {
    if (!ref.read(syncSettingsProvider).config.isConfigured) return;
    try {
      await ref.read(promoSyncProvider).publish();
    } on Object {
      // Photos still work locally; they'll publish on the next edit/sync.
    }
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

/// A focused settings sub-page opened from the hub. Renders one group's
/// controls ([body]) under its own app bar, so the settings landing stays a
/// short, clean list of categories.
class _SettingsDetailPage extends ConsumerWidget {
  final String title;
  final List<Widget> Function(BuildContext, WidgetRef) body;

  const _SettingsDetailPage({required this.title, required this.body});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: body(context, ref),
      ),
    );
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
class _PrinterConfigDialog extends ConsumerStatefulWidget {
  final PrinterRole role;
  final PrinterConfig current;

  const _PrinterConfigDialog({required this.role, required this.current});

  @override
  ConsumerState<_PrinterConfigDialog> createState() =>
      _PrinterConfigDialogState();
}

class _PrinterConfigDialogState extends ConsumerState<_PrinterConfigDialog> {
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

  /// Prints the Chinese diagnostic to this role's printer (uses the saved
  /// connection, so Save first if you just changed it).
  Future<void> _printChineseDiagnostic() async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    final kind = widget.role == PrinterRole.kitchen
        ? domain.PrintJobKind.kitchenTicket
        : domain.PrintJobKind.customerReceipt;
    final result = await ref
        .read(printServiceProvider)
        .printChineseDiagnostic(kind: kind);
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
                    value: domain.TicketCharset.auto,
                    label: Text(l10n.setCharsetAuto),
                  ),
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
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _printChineseDiagnostic,
                  icon: const Icon(Icons.translate_outlined),
                  label: Text(l10n.setPrinterChineseDiagnostic),
                ),
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
        SwitchListTile(
          secondary: const Icon(Icons.storefront_outlined),
          title: Text(context.l10n.setAutoAcceptKiosk),
          subtitle: Text(context.l10n.setAutoAcceptKioskHint),
          value: settings.autoAcceptKiosk,
          onChanged: (v) => ref
              .read(onlineOrderSettingsProvider.notifier)
              .setAutoAcceptKiosk(v),
        ),
        SwitchListTile(
          secondary: const Icon(Icons.credit_card_outlined),
          title: Text(context.l10n.setAcceptOnlinePayment),
          subtitle: Text(context.l10n.setAcceptOnlinePaymentHint),
          value: settings.acceptsOnlinePayment,
          onChanged: (v) => ref
              .read(onlineOrderSettingsProvider.notifier)
              .setAcceptsOnlinePayment(v),
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
  List<DbBackup> _backups = const [];

  @override
  void initState() {
    super.initState();
    _loadBackups();
  }

  /// Loads the local backup ring. Guarded: the backup service needs the real
  /// db key, so it's a no-op in environments (tests) where that's absent.
  Future<void> _loadBackups() async {
    try {
      final list = await ref.read(dbBackupServiceProvider).list();
      if (mounted) setState(() => _backups = list);
    } on Object {
      // No backups available (or not on a real device) — leave the list empty.
    }
  }

  Future<void> _backupNow() async {
    final l10n = context.l10n;
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await ref.read(dbBackupServiceProvider).snapshot(reason: 'manual');
      await _loadBackups();
      if (mounted) setState(() => _message = l10n.setBackupSavedMsg);
    } on Object catch (e) {
      if (mounted) setState(() => _message = l10n.setBackupFailed('$e'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Stages a backup for restore, then closes the app — the swap happens at the
  /// next launch, before the database is opened (it can't replace the live file
  /// while it's held open).
  Future<void> _restoreBackup(DbBackup backup) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.setRestoreBackupTitle),
        content: Text(
          l10n.setRestoreBackupBody(_dateTimeFormat.format(backup.at)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.setRestoreBackupConfirm),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(dbBackupServiceProvider).restore(backup.file);
    } on Object catch (e) {
      if (mounted) setState(() => _message = l10n.setBackupFailed('$e'));
      return;
    }
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(l10n.setRestoreBackupTitle),
        content: Text(l10n.setRestoreStagedMsg),
        actions: [
          FilledButton(
            onPressed: () => exit(0),
            child: Text(l10n.setRestoreClose),
          ),
        ],
      ),
    );
  }

  String _backupReasonLabel(String reason) => switch (reason) {
    'sync' => context.l10n.setBackupReasonSync,
    'restore' => context.l10n.setBackupReasonRestore,
    'forcepush' => context.l10n.setBackupReasonForcepush,
    _ => context.l10n.setBackupReasonManual,
  };

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
          // Recovery — push this device's data back over a cloud that another
          // device overwrote. Only meaningful when signed in (it writes).
          if (settings.isSignedIn) ...[
            const Divider(height: 32),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
              child: Text(
                context.l10n.setRecovery,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
              child: Text(
                context.l10n.setForcePushHint,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: TextButton.icon(
                  onPressed: _busy ? null : _forcePush,
                  icon: const Icon(Icons.cloud_upload_outlined),
                  label: Text(context.l10n.setForcePush),
                ),
              ),
            ),
          ],
        ],
        // Local backups — shown even when the cloud is off; the ring is taken
        // before every sync and on demand, and restores roll the device back.
        const Divider(height: 32),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                context.l10n.setLocalBackups,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              TextButton.icon(
                onPressed: _busy ? null : _backupNow,
                icon: const Icon(Icons.save_outlined),
                label: Text(context.l10n.setBackupNow),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
          child: Text(
            context.l10n.setLocalBackupsHint,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        if (_backups.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: Text(
              context.l10n.setBackupNone,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          )
        else
          for (final b in _backups)
            ListTile(
              dense: true,
              leading: const Icon(Icons.history),
              title: Text(_dateTimeFormat.format(b.at)),
              subtitle: Text(
                '${_backupReasonLabel(b.reason)} · ${(b.bytes / 1024).round()} KB',
              ),
              trailing: TextButton(
                onPressed: _busy ? null : () => _restoreBackup(b),
                child: Text(context.l10n.setBackupRestore),
              ),
            ),
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
    final svc = ref.read(syncServiceProvider);
    // A push of local changes can overwrite cloud data (last-write-wins), so
    // confirm before a sync that has anything to upload — and let the user pick
    // exactly which changes go up (the cloud has no backups). A pull-only sync
    // (nothing pending) is safe and skips the prompt.
    final pending = await svc.pendingPush();
    if (!mounted) return;
    Set<String>? pushIds; // null = push everything (the no-prompt path)
    if (!pending.isEmpty) {
      final firstSync = ref.read(syncSettingsProvider).lastSyncedAt == null;
      final result = await _confirmSync(pending, firstSync);
      if (!mounted) return;
      if (result.choice == _SyncChoice.cancel) return;
      if (result.choice == _SyncChoice.restore) {
        await _restore();
        return;
      }
      pushIds = result.ids; // may be empty → pull only, push nothing
    }
    setState(() {
      _busy = true;
      _message = null;
    });
    final outcome = await svc.syncNow(pushIds: pushIds);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _message = outcome.ok
          ? l10n.setSyncedMsg(outcome.pulled, outcome.pushed)
          : l10n.setSyncFailed('${outcome.error}');
    });
  }

  /// Confirms a "Sync now" that will upload local changes, showing each change
  /// with a checkbox so the user uploads only what they intend (unchecked stays
  /// local). On a first sync it warns harder and offers Restore instead — the
  /// safe action when the cloud may already hold the real data.
  Future<({_SyncChoice choice, Set<String> ids})> _confirmSync(
    PendingPush pending,
    bool firstSync,
  ) async {
    final selected = {for (final c in pending.changes) c.id};
    final result = await showDialog<({_SyncChoice choice, Set<String> ids})>(
      context: context,
      builder: (context) {
        final l10n = context.l10n;
        final cs = Theme.of(context).colorScheme;
        return StatefulBuilder(
          builder: (context, setLocal) => AlertDialog(
            title: Text(l10n.setSyncConfirmTitle),
            content: SizedBox(
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.setSyncSelectBody),
                  if (firstSync)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        l10n.setSyncFirstWarning,
                        style: TextStyle(color: cs.error),
                      ),
                    ),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () => setLocal(
                          () => selected
                            ..clear()
                            ..addAll(pending.changes.map((c) => c.id)),
                        ),
                        child: Text(l10n.setSyncSelectAll),
                      ),
                      TextButton(
                        onPressed: () => setLocal(selected.clear),
                        child: Text(l10n.setSyncSelectNone),
                      ),
                    ],
                  ),
                  Flexible(
                    child: ListView(
                      shrinkWrap: true,
                      children: [
                        for (final c in pending.changes)
                          CheckboxListTile(
                            dense: true,
                            controlAffinity: ListTileControlAffinity.leading,
                            value: selected.contains(c.id),
                            onChanged: (v) => setLocal(
                              () => v == true
                                  ? selected.add(c.id)
                                  : selected.remove(c.id),
                            ),
                            secondary: c.isDelete
                                ? Icon(Icons.delete_outline, color: cs.error)
                                : const Icon(Icons.edit_outlined),
                            title: Text(_changeTitle(context, c)),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, (
                  choice: _SyncChoice.cancel,
                  ids: <String>{},
                )),
                child: Text(l10n.commonCancel),
              ),
              if (firstSync)
                TextButton(
                  onPressed: () => Navigator.pop(context, (
                    choice: _SyncChoice.restore,
                    ids: <String>{},
                  )),
                  child: Text(l10n.setRestoreFromCloud),
                ),
              FilledButton(
                onPressed: () => Navigator.pop(context, (
                  choice: _SyncChoice.sync,
                  ids: {...selected},
                )),
                child: Text(l10n.setSyncUploadSelected(selected.length)),
              ),
            ],
          ),
        );
      },
    );
    return result ?? (choice: _SyncChoice.cancel, ids: <String>{});
  }

  /// A one-line label for a pending change: "Delete · Item · Beef Noodle".
  String _changeTitle(BuildContext context, PendingChange c) {
    final l10n = context.l10n;
    final op = c.isDelete ? l10n.setSyncOpDelete : l10n.setSyncOpUpdate;
    final type = switch (c.entity) {
      'category' => l10n.setSyncEntityCategory,
      'menu_item' => l10n.setSyncEntityItem,
      'modifier' => l10n.setSyncEntityModifier,
      'modifier_group' => l10n.setSyncEntityModifierGroup,
      'dining_table' => l10n.setSyncEntityTable,
      'order' => l10n.setSyncEntityOrder,
      'payment' => l10n.setSyncEntityPayment,
      _ => c.entity,
    };
    final name = c.name;
    return name != null && name.isNotEmpty
        ? '$op · $type · $name'
        : '$op · $type';
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

  /// Recovery: overwrite the cloud with this device's data (and drop cloud rows
  /// from other devices that aren't here). Double-confirmed — it's destructive
  /// to the cloud. A local backup is taken first by the sync service.
  Future<void> _forcePush() async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.setForcePushTitle),
        content: Text(l10n.setForcePushBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.setForcePushConfirm),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() {
      _busy = true;
      _message = null;
    });
    final outcome = await ref
        .read(syncServiceProvider)
        .forcePushFromThisDevice();
    await _loadBackups(); // the force-push took a snapshot first
    if (!mounted) return;
    setState(() {
      _busy = false;
      _message = outcome.ok
          ? l10n.setForcePushedMsg(outcome.pushed)
          : l10n.setForcePushFailed('${outcome.error}');
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
