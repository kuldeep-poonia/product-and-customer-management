import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme.dart';
import '../../core/models.dart';
import '../../core/providers.dart';
import '../../core/widgets.dart';

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() { _tabCtrl.dispose(); _searchCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final products = ref.watch(productsProvider);
    final lowStock = products.where((p) => p.isLowStock).toList();
    final expiringSoon = products.where((p) => p.expiryDate != null && p.expiryDate!.difference(DateTime.now()).inDays <= 14).toList();
    final cs = Theme.of(context).colorScheme;

    final filtered = _query.isEmpty
        ? products
        : ref.read(productsProvider.notifier).search(_query);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory'),
        actions: [
          IconButton(icon: const Icon(Icons.add_box_outlined), onPressed: () => _showAddStockDialog(context), tooltip: 'Add Stock'),
          const SizedBox(width: 4),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          tabs: [
            const Tab(text: 'All Items'),
            Tab(text: 'Low Stock ${lowStock.isNotEmpty ? "(${lowStock.length})" : ""}'),
            Tab(text: 'Expiry ${expiringSoon.isNotEmpty ? "(${expiringSoon.length})" : ""}'),
          ],
          labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            controller: _searchCtrl,
            onChanged: (v) => setState(() => _query = v),
            decoration: InputDecoration(
              hintText: 'Search product...',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _query.isNotEmpty ? IconButton(icon: const Icon(Icons.close, size: 18), onPressed: () { _searchCtrl.clear(); setState(() => _query = ''); }) : null,
            ),
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabCtrl,
            children: [
              _ProductGrid(products: filtered),
              _ProductGrid(products: lowStock),
              _ExpiryList(products: expiringSoon),
            ],
          ),
        ),
      ]),
    );
  }

  void _showAddStockDialog(BuildContext context) {
    final products = ref.read(productsProvider);
    Product? selected;
    final qtyCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => Padding(
          padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Add Stock', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            DropdownButtonFormField<Product>(
              initialValue: selected,
              hint: const Text('Select product'),
              isExpanded: true,
              decoration: const InputDecoration(),
              items: products.map((p) => DropdownMenuItem(value: p, child: Text(p.name, overflow: TextOverflow.ellipsis))).toList(),
              onChanged: (v) => setSt(() => selected = v),
            ),
            const SizedBox(height: 12),
            TextField(controller: qtyCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Quantity to add', suffixText: selected?.unit ?? '')),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  if (selected == null) return;
                  final qty = int.tryParse(qtyCtrl.text) ?? 0;
                  if (qty <= 0) return;
                  ref.read(productsProvider.notifier).addStock(selected!.id, qty);
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Added $qty ${selected!.unit} to ${selected!.name}'), backgroundColor: AppColors.green600, behavior: SnackBarBehavior.floating));
                },
                child: const Text('Add Stock'),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

// ─── PRODUCT GRID ────────────────────────────────────────────────────────────

class _ProductGrid extends ConsumerWidget {
  final List<Product> products;
  const _ProductGrid({required this.products});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (products.isEmpty) {
      return const EmptyState(icon: Icons.inventory_2_outlined, title: 'No items here', subtitle: 'All items are well stocked');
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      itemCount: products.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) => _InventoryTile(product: products[i], ref: ref),
    );
  }
}

class _InventoryTile extends StatelessWidget {
  final Product product;
  final WidgetRef ref;
  const _InventoryTile({required this.product, required this.ref});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final pct = product.stock / (product.lowStockThreshold * 3).clamp(1, 9999);
    final barColor = product.isLowStock ? AppColors.red600 : AppColors.green600;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: product.isLowStock ? Border.all(color: AppColors.red400.withOpacity(0.3)) : null,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: cs.primaryContainer, borderRadius: BorderRadius.circular(10)),
            alignment: Alignment.center,
            child: Text(product.name[0], style: TextStyle(color: cs.primary, fontWeight: FontWeight.w800, fontSize: 18)),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(product.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis)),
              if (product.isLowStock) const LowStockBadge(),
            ]),
            Text(product.category, style: TextStyle(fontSize: 11, color: cs.outline)),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('${product.stock} ${product.unit}', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: product.isLowStock ? AppColors.red600 : cs.onSurface)),
            Text(fmtRupee(product.price), style: TextStyle(fontSize: 12, color: cs.outline)),
          ]),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: pct.clamp(0.0, 1.0), minHeight: 6, backgroundColor: cs.outlineVariant, valueColor: AlwaysStoppedAnimation(barColor)))),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () => _showQuickAddDialog(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: cs.primaryContainer, borderRadius: BorderRadius.circular(8)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.add, size: 14, color: cs.primary),
                const SizedBox(width: 4),
                Text('Add', style: TextStyle(fontSize: 12, color: cs.primary, fontWeight: FontWeight.w600)),
              ]),
            ),
          ),
        ]),
      ]),
    );
  }

  void _showQuickAddDialog(BuildContext context) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Add Stock: ${product.name}'),
        content: TextField(controller: ctrl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Quantity', suffixText: product.unit), autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final qty = int.tryParse(ctrl.text) ?? 0;
              if (qty > 0) ref.read(productsProvider.notifier).addStock(product.id, qty);
              Navigator.pop(ctx);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

// ─── EXPIRY LIST ─────────────────────────────────────────────────────────────

class _ExpiryList extends StatelessWidget {
  final List<Product> products;
  const _ExpiryList({required this.products});

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return const EmptyState(icon: Icons.event_available_outlined, title: 'No expiry alerts', subtitle: 'All products have good shelf life');
    }
    final cs = Theme.of(context).colorScheme;
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      itemCount: products.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final p = products[i];
        final daysLeft = p.expiryDate!.difference(DateTime.now()).inDays;
        final color = daysLeft <= 3 ? AppColors.red600 : daysLeft <= 7 ? AppColors.amber600 : AppColors.blue600;
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(14)),
          child: Row(children: [
            Container(width: 44, height: 44, decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), alignment: Alignment.center, child: Icon(Icons.event, color: color, size: 22)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(p.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
              Text('Stock: ${p.stock} ${p.unit}', style: TextStyle(fontSize: 12, color: cs.outline)),
            ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: Column(children: [
                Text('$daysLeft', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color)),
                Text('days left', style: TextStyle(fontSize: 10, color: color)),
              ]),
            ),
          ]),
        );
      },
    );
  }
}
