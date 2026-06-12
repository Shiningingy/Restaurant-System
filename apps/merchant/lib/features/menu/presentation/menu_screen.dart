import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:restaurant_domain/restaurant_domain.dart' as domain;

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
          title: const Text('Menu'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Items'),
              Tab(text: 'Modifier groups'),
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
                            : const Tooltip(
                                message: 'Hidden from order screen',
                                child: Icon(
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
                  label: const Text('Category'),
                ),
              ),
            ],
          ),
        ),
        const VerticalDivider(width: 1),
        Expanded(
          child: selectedId == null
              ? const Center(
                  child: Text('Create a category to start your menu.'),
                )
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
          title: Text(existing == null ? 'New category' : 'Edit category'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              if (existing != null)
                SwitchListTile(
                  title: const Text('Visible on order screen'),
                  value: isActive,
                  onChanged: (v) => setState(() => isActive = v),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Save'),
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
        label: const Text('Item'),
      ),
      body: items.isEmpty
          ? const Center(child: Text('No items in this category yet.'))
          : ListView.builder(
              padding: const EdgeInsets.only(bottom: 88),
              itemCount: items.length,
              itemBuilder: (context, i) {
                final item = items[i];
                return ListTile(
                  title: Text(item.name),
                  subtitle: item.isActive
                      ? null
                      : const Text('Hidden from order screen'),
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
