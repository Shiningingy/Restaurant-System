import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:restaurant_domain/restaurant_domain.dart' as domain;

import '../../../core/l10n_ext.dart';
import '../application/providers.dart';
import '../data/item_image_repository.dart';

/// Full-screen editor for a menu item: basics (code, name, second name, price,
/// visibility), user-defined custom fields, photos, and modifier groups.
/// Replaces the old cramped dialog. Reached from the Menu tab (manager-gated).
class ItemEditorScreen extends ConsumerStatefulWidget {
  final String categoryId;
  final String? itemId;

  const ItemEditorScreen({super.key, required this.categoryId, this.itemId});

  @override
  ConsumerState<ItemEditorScreen> createState() => _ItemEditorScreenState();
}

class _AttrDraft {
  final String id;
  final TextEditingController label;
  final TextEditingController value;
  _AttrDraft(this.id, String label, String value)
    : label = TextEditingController(text: label),
      value = TextEditingController(text: value);
  void dispose() {
    label.dispose();
    value.dispose();
  }
}

const _maxFields = 5;
const _maxImages = 3;

class _ItemEditorScreenState extends ConsumerState<ItemEditorScreen> {
  final _code = TextEditingController();
  final _name = TextEditingController();
  final _nameSecondary = TextEditingController();
  final _description = TextEditingController();
  final _price = TextEditingController();
  bool _isActive = true;
  final Set<String> _groupIds = {};
  final List<_AttrDraft> _attrs = [];

  late final String _id = widget.itemId ?? domain.newId();
  bool _loading = true;
  int _sortOrder = 0;

  bool get _isNew => widget.itemId == null;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (widget.itemId == null) {
      setState(() => _loading = false);
      return;
    }
    final item = await ref.read(menuRepositoryProvider).getItem(widget.itemId!);
    if (!mounted) return;
    if (item != null) {
      _code.text = item.code ?? '';
      _name.text = item.name;
      _nameSecondary.text = item.nameSecondary ?? '';
      _description.text = item.description ?? '';
      _price.text = (item.price.cents / 100).toStringAsFixed(2);
      _isActive = item.isActive;
      _sortOrder = item.sortOrder;
      _groupIds.addAll(item.modifierGroupIds);
      for (final a in item.attributes) {
        _attrs.add(_AttrDraft(a.id, a.label, a.value));
      }
    }
    setState(() => _loading = false);
  }

  @override
  void dispose() {
    _code.dispose();
    _name.dispose();
    _nameSecondary.dispose();
    _description.dispose();
    _price.dispose();
    for (final a in _attrs) {
      a.dispose();
    }
    super.dispose();
  }

  domain.Money? get _parsedPrice => domain.Money.tryParse(_price.text);

  bool get _valid =>
      _name.text.trim().isNotEmpty &&
      _parsedPrice != null &&
      !_parsedPrice!.isNegative;

  String? _clean(TextEditingController c) {
    final t = c.text.trim();
    return t.isEmpty ? null : t;
  }

  domain.MenuItem _build() => domain.MenuItem(
    id: _id,
    categoryId: widget.categoryId,
    name: _name.text.trim(),
    price: _parsedPrice!,
    code: _clean(_code),
    nameSecondary: _clean(_nameSecondary),
    description: _clean(_description),
    sortOrder: _sortOrder,
    isActive: _isActive,
    modifierGroupIds: _groupIds.toList(),
    attributes: [
      for (var i = 0; i < _attrs.length; i++)
        if (_attrs[i].label.text.trim().isNotEmpty)
          domain.MenuItemAttribute(
            id: _attrs[i].id,
            label: _attrs[i].label.text.trim(),
            value: _attrs[i].value.text.trim(),
            sortOrder: i,
          ),
    ],
  );

  Future<void> _save() async {
    await ref.read(menuRepositoryProvider).upsertItem(_build());
    if (mounted) Navigator.pop(context);
  }

  Future<void> _delete() async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.menuDeleteItem),
        content: Text(l10n.menuDeleteItemConfirm(_name.text.trim())),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.commonDelete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(menuRepositoryProvider).deleteItem(_id);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final allGroups = ref.watch(modifierGroupsProvider).value ?? const [];
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isNew ? context.l10n.menuNewItem : context.l10n.menuEditItem,
        ),
        actions: [
          if (!_isNew)
            IconButton(
              tooltip: context.l10n.commonDelete,
              icon: const Icon(Icons.delete_outline),
              onPressed: _delete,
            ),
          TextButton(
            onPressed: _valid ? _save : null,
            child: Text(context.l10n.commonSave),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // --- Basics ---
                TextField(
                  controller: _code,
                  decoration: InputDecoration(
                    labelText: context.l10n.itemCodeLabel,
                  ),
                ),
                TextField(
                  controller: _name,
                  autofocus: _isNew,
                  decoration: InputDecoration(labelText: context.l10n.menuName),
                  onChanged: (_) => setState(() {}),
                ),
                TextField(
                  controller: _nameSecondary,
                  decoration: InputDecoration(
                    labelText: context.l10n.itemNameSecondaryLabel,
                  ),
                ),
                TextField(
                  controller: _description,
                  decoration: InputDecoration(
                    labelText: context.l10n.itemDescriptionLabel,
                  ),
                  maxLines: 2,
                  textCapitalization: TextCapitalization.sentences,
                ),
                TextField(
                  controller: _price,
                  decoration: InputDecoration(
                    labelText: context.l10n.menuPrice,
                    prefixText: r'$',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(context.l10n.menuVisibleOnOrderScreen),
                  value: _isActive,
                  onChanged: (v) => setState(() => _isActive = v),
                ),
                const Divider(height: 32),

                // --- Custom fields ---
                _SectionHeader(title: context.l10n.itemFieldsSection),
                for (var i = 0; i < _attrs.length; i++)
                  _AttrRow(
                    draft: _attrs[i],
                    onRemove: () =>
                        setState(() => _attrs.removeAt(i).dispose()),
                  ),
                if (_attrs.length < _maxFields)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: PopupMenuButton<String>(
                      tooltip: context.l10n.itemAddField,
                      onSelected: (v) => _addField(v.isEmpty ? null : v),
                      itemBuilder: (context) => [
                        for (final preset in _fieldPresets(context))
                          PopupMenuItem(value: preset, child: Text(preset)),
                        PopupMenuItem(
                          value: '',
                          child: Text(context.l10n.itemFieldCustom),
                        ),
                      ],
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.add),
                            const SizedBox(width: 4),
                            Text(context.l10n.itemAddField),
                          ],
                        ),
                      ),
                    ),
                  ),
                const Divider(height: 32),

                // --- Photos ---
                _SectionHeader(title: context.l10n.itemImagesSection),
                if (_isNew)
                  Text(
                    context.l10n.itemSaveFirstForPhotos,
                    style: Theme.of(context).textTheme.bodySmall,
                  )
                else
                  _ImagesEditor(itemId: _id),
                const Divider(height: 32),

                // --- Modifier groups ---
                if (allGroups.isNotEmpty) ...[
                  _SectionHeader(title: context.l10n.menuModifierGroups),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final g in allGroups)
                        FilterChip(
                          label: Text(g.name),
                          selected: _groupIds.contains(g.id),
                          onSelected: (sel) => setState(
                            () => sel
                                ? _groupIds.add(g.id)
                                : _groupIds.remove(g.id),
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
    );
  }

  void _addField([String? presetLabel]) {
    setState(
      () => _attrs.add(_AttrDraft(domain.newId(), presetLabel ?? '', '')),
    );
  }

  List<String> _fieldPresets(BuildContext context) => [
    context.l10n.fieldPresetDescription,
    context.l10n.fieldPresetIngredients,
    context.l10n.fieldPresetAllergens,
    context.l10n.fieldPresetSpice,
    context.l10n.fieldPresetNotes,
  ];
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(title, style: Theme.of(context).textTheme.titleMedium),
  );
}

class _AttrRow extends StatelessWidget {
  final _AttrDraft draft;
  final VoidCallback onRemove;
  const _AttrRow({required this.draft, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          SizedBox(
            width: 140,
            child: TextField(
              controller: draft.label,
              decoration: InputDecoration(
                labelText: context.l10n.itemFieldLabelHint,
                isDense: true,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: draft.value,
              decoration: InputDecoration(
                labelText: context.l10n.itemFieldValueHint,
                isDense: true,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: context.l10n.commonDelete,
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}

/// Live photo management for a saved item (thumbnails + add/rename/remove).
class _ImagesEditor extends ConsumerWidget {
  final String itemId;
  const _ImagesEditor({required this.itemId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final images = ref.watch(itemImagesProvider(itemId)).value ?? const [];
    final repo = ref.read(itemImageRepositoryProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final img in images)
              _Thumb(
                image: img,
                onRename: () => _rename(context, repo, img),
                onDelete: () => repo.deleteImage(img.id),
              ),
          ],
        ),
        if (images.length < _maxImages)
          TextButton.icon(
            onPressed: () => _add(context, ref),
            icon: const Icon(Icons.add_a_photo_outlined),
            label: Text(context.l10n.itemAddImage),
          ),
      ],
    );
  }

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    const group = XTypeGroup(
      label: 'images',
      extensions: ['jpg', 'jpeg', 'png', 'webp', 'gif', 'bmp'],
    );
    final file = await openFile(acceptedTypeGroups: [group]);
    if (file == null) return;
    await ref
        .read(itemImageRepositoryProvider)
        .addImage(itemId: itemId, label: '', sourcePath: file.path);
  }

  Future<void> _rename(
    BuildContext context,
    ItemImageRepository repo,
    ItemImage img,
  ) async {
    final controller = TextEditingController(text: img.label);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.itemRenameImage),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            labelText: context.l10n.itemImageLabelHint,
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
    if (ok == true) await repo.renameImage(img.id, controller.text.trim());
    controller.dispose();
  }
}

class _Thumb extends StatelessWidget {
  final ItemImage image;
  final VoidCallback onRename;
  final VoidCallback onDelete;
  const _Thumb({
    required this.image,
    required this.onRename,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                File(image.path),
                width: 96,
                height: 96,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  width: 96,
                  height: 96,
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: const Icon(Icons.broken_image_outlined),
                ),
              ),
            ),
            Positioned(
              right: 0,
              top: 0,
              child: IconButton(
                icon: const Icon(Icons.cancel, size: 20),
                tooltip: context.l10n.commonDelete,
                onPressed: onDelete,
              ),
            ),
          ],
        ),
        SizedBox(
          width: 96,
          child: TextButton(
            onPressed: onRename,
            child: Text(
              image.label.isEmpty ? context.l10n.commonEdit : image.label,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ),
      ],
    );
  }
}
