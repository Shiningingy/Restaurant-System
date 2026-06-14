import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:restaurant_domain/restaurant_domain.dart' as domain;

import '../../../core/l10n_ext.dart';
import '../application/providers.dart';
import 'item_edit_dialog.dart';
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
                child: ListView(
                  children: [
                    for (final c in categories)
                      ListTile(
                        title: Text(c.name),
                        selected: c.id == selectedId,
                        trailing: c.isActive
                            ? null
                            : Tooltip(
                                message: context.l10n.menuHiddenFromOrderScreen,
                                child: const Icon(
                                  Icons.visibility_off_outlined,
                                  size: 18,
                                ),
                              ),
                        onTap: () => setState(() => _selectedCategoryId = c.id),
                        onLongPress: () => _editCategory(context, c),
                      ),
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

  Future<void> _editCategory(
    BuildContext context,
    domain.Category? existing,
  ) async {
    final controller = TextEditingController(text: existing?.name ?? '');
    var isActive = existing?.isActive ?? true;
    final saved = await showDialog<bool>(
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
        onPressed: () =>
            showItemEditDialog(context, ref, categoryId: categoryId),
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
                  title: Text(item.name),
                  subtitle: item.isActive
                      ? null
                      : Text(context.l10n.menuHiddenFromOrderScreen),
                  trailing: Text(
                    item.price.format(),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  onTap: () => showItemEditDialog(
                    context,
                    ref,
                    categoryId: categoryId,
                    itemId: item.id,
                  ),
                );
              },
            ),
    );
  }
}
