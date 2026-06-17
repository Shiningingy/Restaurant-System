import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:restaurant_domain/restaurant_domain.dart' as domain;

import '../../../core/l10n_ext.dart';
import '../../menu/application/providers.dart' as menu;
import '../data/image_region_cropper.dart';
import '../domain/code_sequencer.dart';
import '../domain/geometry.dart';
import '../domain/item_draft.dart';

/// Editable review of the drafts captured during a sweep. The merchant fixes any
/// OCR slips, then "Save all" writes them as real menu items (and crops any photo
/// regions into the items' images). Pops with the number of items saved.
class DraftReviewScreen extends ConsumerStatefulWidget {
  final String categoryId;
  final String sourcePhotoPath;
  final List<ItemDraft> drafts;

  const DraftReviewScreen({
    super.key,
    required this.categoryId,
    required this.sourcePhotoPath,
    required this.drafts,
  });

  @override
  ConsumerState<DraftReviewScreen> createState() => _DraftReviewScreenState();
}

class _Row {
  final TextEditingController code;
  final TextEditingController name;
  final TextEditingController nameSecondary;
  final TextEditingController price;
  final List<({String label, TextEditingController value})> attrs;
  final List<PixelBox> imageBoxes;

  _Row(ItemDraft d)
    : code = TextEditingController(text: d.code ?? ''),
      name = TextEditingController(text: d.name ?? ''),
      nameSecondary = TextEditingController(text: d.nameSecondary ?? ''),
      price = TextEditingController(
        text: d.price == null ? '' : (d.price!.cents / 100).toStringAsFixed(2),
      ),
      attrs = [
        for (final a in d.attributes)
          (label: a.label, value: TextEditingController(text: a.value)),
      ],
      imageBoxes = List.of(d.imageBoxes);

  void dispose() {
    code.dispose();
    name.dispose();
    nameSecondary.dispose();
    price.dispose();
    for (final a in attrs) {
      a.value.dispose();
    }
  }
}

class _DraftReviewScreenState extends ConsumerState<DraftReviewScreen> {
  late final List<_Row> _rows = [for (final d in widget.drafts) _Row(d)];
  bool _saving = false;

  @override
  void dispose() {
    for (final r in _rows) {
      r.dispose();
    }
    super.dispose();
  }

  Future<void> _saveAll() async {
    setState(() => _saving = true);
    final repo = ref.read(menu.menuRepositoryProvider);
    final images = ref.read(menu.itemImageRepositoryProvider);
    const cropper = ImageRegionCropper();
    final existing = await repo.watchItemsInCategory(widget.categoryId).first;
    var sortOrder = existing.length;
    var saved = 0;
    // Keep codes unique across the batch and the category (AX1, AX2 — not AX1, AX1).
    final usedCodes = {
      for (final item in existing)
        if (item.code != null && item.code!.isNotEmpty) item.code!,
    };

    for (final row in _rows) {
      final name = row.name.text.trim();
      final code = nextUniqueCode(row.code.text.trim(), usedCodes);
      if (name.isEmpty && code.isEmpty) continue; // nothing identifiable
      if (code.isNotEmpty) usedCodes.add(code);

      final id = domain.newId();
      await repo.upsertItem(
        domain.MenuItem(
          id: id,
          categoryId: widget.categoryId,
          name: name.isEmpty ? code : name,
          price:
              domain.Money.tryParse(row.price.text.trim()) ?? domain.Money.zero,
          code: code.isEmpty ? null : code,
          nameSecondary: row.nameSecondary.text.trim().isEmpty
              ? null
              : row.nameSecondary.text.trim(),
          sortOrder: sortOrder++,
          attributes: [
            for (var i = 0; i < row.attrs.length; i++)
              if (row.attrs[i].value.text.trim().isNotEmpty)
                domain.MenuItemAttribute(
                  id: domain.newId(),
                  label: row.attrs[i].label,
                  value: row.attrs[i].value.text.trim(),
                  sortOrder: i,
                ),
          ],
        ),
      );

      for (final box in row.imageBoxes) {
        try {
          final temp = await cropper.cropToTempFile(
            widget.sourcePhotoPath,
            box,
          );
          await images.addImage(itemId: id, label: '', sourcePath: temp);
        } catch (_) {
          // A bad crop shouldn't abort the whole import.
        }
      }
      saved++;
    }

    if (mounted) Navigator.pop(context, saved);
  }

  void _discard(int i) {
    setState(() {
      _rows.removeAt(i).dispose();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.captureReviewTitle),
        actions: [
          if (!_saving)
            TextButton(
              onPressed: _rows.isEmpty ? null : _saveAll,
              child: Text(context.l10n.captureSaveAll),
            ),
        ],
      ),
      body: _saving
          ? const Center(child: CircularProgressIndicator())
          : _rows.isEmpty
          ? Center(child: Text(context.l10n.captureNoDrafts))
          : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: _rows.length,
              itemBuilder: (context, i) => _card(context, i),
            ),
    );
  }

  Widget _card(BuildContext context, int i) {
    final row = _rows[i];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SizedBox(
                  width: 90,
                  child: TextField(
                    controller: row.code,
                    decoration: InputDecoration(
                      labelText: context.l10n.captureFieldCode,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: row.name,
                    decoration: InputDecoration(
                      labelText: context.l10n.captureFieldName,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: context.l10n.captureDiscardDraft,
                  onPressed: () => _discard(i),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: row.nameSecondary,
                    decoration: InputDecoration(
                      labelText: context.l10n.captureFieldNameSecondary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 120,
                  child: TextField(
                    controller: row.price,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: context.l10n.captureFieldPrice,
                    ),
                  ),
                ),
              ],
            ),
            for (final a in row.attrs)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: TextField(
                  controller: a.value,
                  decoration: InputDecoration(labelText: a.label),
                ),
              ),
            if (row.imageBoxes.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    const Icon(Icons.image_outlined, size: 18),
                    const SizedBox(width: 4),
                    Text('${row.imageBoxes.length}'),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
