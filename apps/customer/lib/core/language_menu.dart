import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/storefront/application/providers.dart';
import 'l10n_ext.dart';

/// App-bar action to switch the UI language (System / English / 中文).
/// Uses string values because [PopupMenuButton] treats a null value as a
/// cancel, which would swallow the "system default" choice.
class LanguageMenu extends ConsumerWidget {
  const LanguageMenu({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(localePreferenceProvider);
    return PopupMenuButton<String>(
      icon: const Icon(Icons.translate),
      tooltip: context.l10n.languageMenuTooltip,
      initialValue: current?.languageCode ?? 'system',
      onSelected: (v) => ref
          .read(localePreferenceProvider.notifier)
          .set(v == 'system' ? null : Locale(v)),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'system',
          child: Text(context.l10n.languageSystem),
        ),
        const PopupMenuItem(value: 'en', child: Text('English')),
        const PopupMenuItem(value: 'zh', child: Text('中文')),
      ],
    );
  }
}
