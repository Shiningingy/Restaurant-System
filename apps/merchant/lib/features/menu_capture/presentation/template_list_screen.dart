import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:restaurant_domain/restaurant_domain.dart' as domain;

import '../../../core/l10n_ext.dart';
import '../application/providers.dart';
import '../domain/capture_template.dart';
import 'template_editor_screen.dart';

/// Lists the merchant's capture templates and lets them create, rename, delete,
/// or open one in the region editor.
class TemplateListScreen extends ConsumerWidget {
  const TemplateListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templates = ref.watch(captureTemplatesProvider);

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.captureTemplatesTitle)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _create(context, ref),
        icon: const Icon(Icons.add),
        label: Text(context.l10n.captureNewTemplate),
      ),
      body: templates.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  context.l10n.captureNoTemplates,
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : ListView(
              children: [
                for (final t in templates)
                  ListTile(
                    title: Text(t.name),
                    subtitle: Text('${t.regions.length}'),
                    onTap: () => _open(context, t),
                    trailing: PopupMenuButton<String>(
                      onSelected: (v) {
                        if (v == 'rename') _rename(context, ref, t);
                        if (v == 'delete') _delete(context, ref, t);
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'rename',
                          child: Text(context.l10n.captureRenameTemplate),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Text(context.l10n.captureDeleteTemplate),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }

  Future<void> _open(BuildContext context, CaptureTemplate template) =>
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => TemplateEditorScreen(template: template),
        ),
      );

  Future<void> _create(BuildContext context, WidgetRef ref) async {
    final name = await _promptName(context, ref, '');
    if (name == null || name.isEmpty || !context.mounted) return;
    await _open(
      context,
      CaptureTemplate(id: domain.newId(), name: name, regions: const []),
    );
  }

  Future<void> _rename(
    BuildContext context,
    WidgetRef ref,
    CaptureTemplate template,
  ) async {
    final name = await _promptName(context, ref, template.name);
    if (name == null || name.isEmpty) return;
    await ref
        .read(captureTemplatesProvider.notifier)
        .save(template.copyWith(name: name));
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    CaptureTemplate template,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(context.l10n.captureDeleteTemplateConfirm(template.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.captureDeleteTemplate),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(captureTemplatesProvider.notifier).delete(template.id);
    }
  }

  Future<String?> _promptName(
    BuildContext context,
    WidgetRef ref,
    String initial,
  ) {
    final controller = TextEditingController(text: initial);
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            labelText: context.l10n.captureTemplateNameHint,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: Text(context.l10n.commonSave),
          ),
        ],
      ),
    );
  }
}
