import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n_ext.dart';
import '../../../core/settings/providers.dart';
import '../help_content.dart';

/// The in-app user guide (offline). Reached from the first-run welcome dialog
/// and from Settings → Help.
class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final zh = Localizations.localeOf(context).languageCode == 'zh';
    final sections = merchantHelp(zh: zh);
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.helpTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          for (final s in sections) ...[
            Padding(
              padding: const EdgeInsets.only(top: 20, bottom: 8),
              child: Text(
                s.title,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            for (final line in s.body) _Line(line),
          ],
        ],
      ),
    );
  }
}

/// Renders one content line: `- ` → bullet, `# ` → sub-heading, else paragraph.
class _Line extends StatelessWidget {
  final String line;

  const _Line(this.line);

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme.bodyLarge;
    if (line.startsWith('# ')) {
      return Padding(
        padding: const EdgeInsets.only(top: 10, bottom: 4),
        child: Text(
          line.substring(2),
          style: Theme.of(context).textTheme.titleMedium,
        ),
      );
    }
    if (line.startsWith('- ')) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('•  ', style: text),
            Expanded(child: Text(line.substring(2), style: text)),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(line, style: text),
    );
  }
}

/// Opens the guide.
void openHelp(BuildContext context) {
  Navigator.of(
    context,
  ).push(MaterialPageRoute<void>(builder: (_) => const HelpScreen()));
}

/// Shows the one-time welcome dialog the first time the app is opened, then
/// records that it has been seen so it never shows again. Wrap the home with
/// this. [child] is shown unchanged.
class FirstRunHelpGate extends ConsumerStatefulWidget {
  final Widget child;

  const FirstRunHelpGate({super.key, required this.child});

  @override
  ConsumerState<FirstRunHelpGate> createState() => _FirstRunHelpGateState();
}

class _FirstRunHelpGateState extends ConsumerState<FirstRunHelpGate> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeWelcome());
  }

  Future<void> _maybeWelcome() async {
    final repo = ref.read(settingsRepositoryProvider);
    if (repo.helpSeen) return;
    await repo.setHelpSeen(true);
    if (!mounted) return;
    final open = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.menu_book_outlined),
        title: Text(context.l10n.helpWelcomeTitle),
        content: Text(context.l10n.helpWelcomeBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.helpNotNow),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.helpOpenGuide),
          ),
        ],
      ),
    );
    if (open == true && mounted) openHelp(context);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
