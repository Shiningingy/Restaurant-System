import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:restaurant_domain/restaurant_domain.dart' as domain;

import 'package:restaurant_ui/restaurant_ui.dart';

import '../../../core/l10n_ext.dart';
import '../../../core/widgets/item_name_lines.dart';
import '../../menu_capture/presentation/capture_screen.dart';
import '../../online_orders/application/providers.dart';
import '../application/providers.dart';
import '../data/sample_menu.dart';
import 'item_editor_screen.dart';
import 'modifier_groups_tab.dart';

class MenuScreen extends ConsumerStatefulWidget {
  const MenuScreen({super.key});

  @override
  ConsumerState<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends ConsumerState<MenuScreen> {
  String? _selectedCategoryId;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(context.l10n.menuTitle),
          actions: [
            if (ref.watch(onlineOrderingEnabledProvider))
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: TextButton.icon(
                  onPressed: () => _publishMenu(context),
                  icon: const Icon(Icons.cloud_upload_outlined),
                  label: Text(context.l10n.inboxPublishMenu),
                ),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: TextButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CaptureScreen()),
                ),
                icon: const Icon(Icons.photo_camera_outlined),
                label: Text(context.l10n.captureImportFromPhoto),
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (v) {
                if (v == 'sample') _loadSampleMenu(context);
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'sample',
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.restaurant_menu),
                    title: Text(context.l10n.menuLoadSample),
                  ),
                ),
              ],
            ),
          ],
          bottom: TabBar(
            tabs: [
              Tab(text: context.l10n.menuItems),
              Tab(text: context.l10n.menuModifierGroups),
            ],
          ),
        ),
        body: TabBarView(
          children: [_buildItemsTab(context), const ModifierGroupsTab()],
        ),
      ),
    );
  }

  /// Publishes the live menu to the storefront (so customers + kiosks see the
  /// latest). Moved here from the Inbox so editing and publishing live together.
  Future<void> _publishMenu(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    try {
      await ref.read(inboxServiceProvider).publishMenu();
      messenger.showSnackBar(SnackBar(content: Text(l10n.inboxMenuPublished)));
    } on Object catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.inboxPublishFailed('$e'))),
      );
    }
  }

  Widget _buildItemsTab(BuildContext context) {
    final categories = ref.watch(categoriesProvider).value ?? const [];
    final selectedId =
        _selectedCategoryId ??
        (categories.isEmpty ? null : categories.first.id);

    return Row(
      children: [
        SizedBox(
          width: 260,
          child: Column(
            children: [
              Expanded(
                // Drag the handle to reorder; the order is the order categories
                // appear on the order screen. Tap selects, long-press edits.
                child: ReorderableListView(
                  buildDefaultDragHandles: false,
                  onReorderItem: (oldIndex, newIndex) =>
                      _reorderCategories(oldIndex, newIndex, categories),
                  children: [
                    for (var i = 0; i < categories.length; i++)
                      _categoryTile(context, categories[i], i, selectedId),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: OutlinedButton.icon(
                  onPressed: () => _editCategory(context, null),
                  icon: const Icon(Icons.add),
                  label: Text(context.l10n.menuCategory),
                ),
              ),
            ],
          ),
        ),
        const VerticalDivider(width: 1),
        Expanded(
          child: selectedId == null
              ? Center(child: Text(context.l10n.menuCreateCategoryToStart))
              : _ItemsList(categoryId: selectedId),
        ),
      ],
    );
  }

  /// One category row, with a drag handle for reordering. Keyed by id so the
  /// reorderable list tracks it across moves.
  Widget _categoryTile(
    BuildContext context,
    domain.Category c,
    int index,
    String? selectedId,
  ) {
    return ListTile(
      key: ValueKey(c.id),
      leading: ReorderableDragStartListener(
        index: index,
        child: const Icon(Icons.drag_indicator),
      ),
      title: Text(c.name),
      selected: c.id == selectedId,
      trailing: c.isActive
          ? null
          : Tooltip(
              message: context.l10n.menuHiddenFromOrderScreen,
              child: const Icon(Icons.visibility_off_outlined, size: 18),
            ),
      onTap: () => setState(() => _selectedCategoryId = c.id),
      onLongPress: () => _editCategory(context, c),
    );
  }

  /// Commits a drag-reorder: moves the category and persists the new order
  /// (which also syncs to other devices). [newIndex] is already adjusted for
  /// the removed item (onReorderItem contract).
  Future<void> _reorderCategories(
    int oldIndex,
    int newIndex,
    List<domain.Category> categories,
  ) async {
    final reordered = [...categories];
    final moved = reordered.removeAt(oldIndex);
    reordered.insert(newIndex, moved);
    await ref.read(menuRepositoryProvider).reorderCategories(reordered);
  }

  /// Loads the Yee Sushi sample menu — a realistic bilingual menu for trying
  /// out ordering and printing. Idempotent (deterministic ids), so re-loading
  /// just refreshes the same rows.
  Future<void> _loadSampleMenu(BuildContext context) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(l10n.menuLoadSampleConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.menuLoadSample),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await seedYeeSushiMenu(ref.read(menuRepositoryProvider));
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.menuLoadSampleDone)));
    }
  }

  Future<void> _editCategory(
    BuildContext context,
    domain.Category? existing,
  ) async {
    final controller = TextEditingController(text: existing?.name ?? '');
    var isActive = existing?.isActive ?? true;
    final result = await showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(
            existing == null
                ? context.l10n.menuNewCategory
                : context.l10n.menuEditCategory,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                autofocus: true,
                decoration: InputDecoration(labelText: context.l10n.menuName),
              ),
              if (existing != null)
                SwitchListTile(
                  title: Text(context.l10n.menuVisibleOnOrderScreen),
                  value: isActive,
                  onChanged: (v) => setState(() => isActive = v),
                ),
            ],
          ),
          actions: [
            if (existing != null)
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                ),
                onPressed: () => Navigator.pop(context, 'delete'),
                child: Text(context.l10n.commonDelete),
              ),
            TextButton(
              onPressed: () => Navigator.pop(context, 'cancel'),
              child: Text(context.l10n.commonCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, 'save'),
              child: Text(context.l10n.commonSave),
            ),
          ],
        ),
      ),
    );
    if (result == 'delete' && existing != null) {
      if (context.mounted) await _deleteCategory(context, existing);
      return;
    }
    if (result == 'save' && controller.text.trim().isNotEmpty) {
      final repo = ref.read(menuRepositoryProvider);
      final categories = ref.read(categoriesProvider).value ?? const [];
      await repo.upsertCategory(
        existing?.copyWith(name: controller.text.trim(), isActive: isActive) ??
            domain.Category(
              id: domain.newId(),
              name: controller.text.trim(),
              sortOrder: categories.length,
            ),
      );
    }
  }

  /// Confirms (showing how many items will go with it) then cascade-deletes
  /// the category. If it was the selected one, selection falls back to the
  /// first remaining category on next build.
  Future<void> _deleteCategory(
    BuildContext context,
    domain.Category category,
  ) async {
    final l10n = context.l10n;
    final repo = ref.read(menuRepositoryProvider);
    final itemCount =
        (await repo.watchItemsInCategory(category.id).first).length;
    if (!context.mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.menuDeleteCategory),
        content: Text(l10n.menuDeleteCategoryConfirm(category.name, itemCount)),
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
    await repo.deleteCategory(category.id);
    if (_selectedCategoryId == category.id) {
      setState(() => _selectedCategoryId = null);
    }
  }
}

class _ItemsList extends ConsumerWidget {
  final String categoryId;

  const _ItemsList({required this.categoryId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items =
        ref.watch(itemsInCategoryProvider(categoryId)).value ?? const [];
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ItemEditorScreen(categoryId: categoryId),
          ),
        ),
        icon: const Icon(Icons.add),
        label: Text(context.l10n.menuItem),
      ),
      body: items.isEmpty
          ? Center(child: Text(context.l10n.menuNoItemsInCategory))
          : ListView.builder(
              padding: const EdgeInsets.only(bottom: 88),
              itemCount: items.length,
              itemBuilder: (context, i) {
                final item = items[i];
                return ListTile(
                  title: ItemNameLines(
                    code: item.code,
                    name: item.name,
                    nameSecondary: item.nameSecondary,
                  ),
                  subtitle: item.isActive
                      ? null
                      : Text(context.l10n.menuHiddenFromOrderScreen),
                  trailing: Text(
                    item.price.format(),
                    style: moneyTextStyle(
                      Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ItemEditorScreen(
                        categoryId: categoryId,
                        itemId: item.id,
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
