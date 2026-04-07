import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../app/theme.dart';
import '../../core/models.dart';
import '../../core/providers.dart';

// ── Backup state ──────────────────────────────────────────────────────────────

class BackupMeta {
  final DateTime date;
  final int productCount;
  final int billCount;
  final int customerCount;
  final int supplierCount;
  final int orderCount;
  final String sizeLabel;

  const BackupMeta({
    required this.date,
    required this.productCount,
    required this.billCount,
    required this.customerCount,
    required this.supplierCount,
    required this.orderCount,
    required this.sizeLabel,
  });
}

class BackupNotifier extends StateNotifier<List<BackupMeta>> {
  BackupNotifier() : super([]) {
    _loadHistory();
  }

  static const _kHistory = 'backup_history';

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_kHistory) ?? [];
    final list = raw.map((e) {
      final m = jsonDecode(e) as Map<String, dynamic>;
      return BackupMeta(
        date: DateTime.parse(m['date'] as String),
        productCount: m['products'] as int,
        billCount: m['bills'] as int,
        customerCount: m['customers'] as int,
        supplierCount: m['suppliers'] as int,
        orderCount: m['orders'] as int,
        sizeLabel: m['size'] as String,
      );
    }).toList();
    list.sort((a, b) => b.date.compareTo(a.date));
    state = list;
  }

  Future<void> _saveHistory(List<BackupMeta> list) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _kHistory,
      list.map((m) => jsonEncode({
        'date': m.date.toIso8601String(),
        'products': m.productCount,
        'bills': m.billCount,
        'customers': m.customerCount,
        'suppliers': m.supplierCount,
        'orders': m.orderCount,
        'size': m.sizeLabel,
      })).toList(),
    );
  }

  Future<BackupMeta?> createBackup({
    required List<Product> products,
    required List<Bill> bills,
    required List<Customer> customers,
    required List<Supplier> suppliers,
    required List<Order> orders,
    String range = 'all',
  }) async {
    try {
      // Filter by range
      final now = DateTime.now();
      List<Bill> filteredBills = bills;
      if (range == '7days') {
        filteredBills = bills.where((b) => now.difference(b.createdAt).inDays <= 7).toList();
      } else if (range == '30days') {
        filteredBills = bills.where((b) => now.difference(b.createdAt).inDays <= 30).toList();
      }

      final payload = {
        'version': '1.0',
        'created_at': now.toIso8601String(),
        'range': range,
        'stats': {
          'products': products.length,
          'bills': filteredBills.length,
          'customers': customers.length,
          'suppliers': suppliers.length,
          'orders': orders.length,
        },
        'products': products.map((p) => {
          'id': p.id,
          'name': p.name,
          'name_hi': p.nameHi,
          'category': p.category,
          'price': p.price,
          'cost_price': p.costPrice,
          'stock': p.stock,
          'low_stock_threshold': p.lowStockThreshold,
          'unit': p.unit,
          'supplier': p.supplier,
        }).toList(),
        'bills': filteredBills.map((b) => {
          'id': b.id,
          'customer_name': b.customerName,
          'customer_phone': b.customerPhone,
          'payment_mode': b.paymentMode.name,
          'discount': b.discount,
          'total': b.total,
          'is_paid': b.isPaid,
          'created_at': b.createdAt.toIso8601String(),
          'items': b.items.map((i) => {
            'product_name': i.product.name,
            'qty': i.qty,
            'unit_price': i.unitPrice,
            'total': i.total,
          }).toList(),
        }).toList(),
        'customers': customers.map((c) => {
          'id': c.id,
          'name': c.name,
          'phone': c.phone,
          'address': c.address,
          'total_due': c.totalDue,
          'khata': c.khata.map((k) => {
            'type': k.type,
            'amount': k.amount,
            'note': k.note,
            'date': k.date.toIso8601String(),
          }).toList(),
        }).toList(),
        'suppliers': suppliers.map((s) => {
          'id': s.id,
          'name': s.name,
          'phone': s.phone,
          'company': s.companyName,
          'amount_due': s.amountDue,
          'product_notes': s.productNotes,
        }).toList(),
        'orders': orders.map((o) => {
          'id': o.id,
          'customer': o.customerName,
          'total': o.total,
          'status': o.status.name,
          'created_at': o.createdAt.toIso8601String(),
        }).toList(),
      };

      final jsonStr = const JsonEncoder.withIndent('  ').convert(payload);
      final bytes = utf8.encode(jsonStr);
      final sizeKb = (bytes.length / 1024).toStringAsFixed(1);

      // Write to temp file
      final dir = await getTemporaryDirectory();
      final fileName = 'shopiq_backup_${now.year}${now.month.toString().padLeft(2,'0')}${now.day.toString().padLeft(2,'0')}_${now.hour.toString().padLeft(2,'0')}${now.minute.toString().padLeft(2,'0')}.json';
      final file = File('${dir.path}/$fileName');
      await file.writeAsString(jsonStr);

      final meta = BackupMeta(
        date: now,
        productCount: products.length,
        billCount: filteredBills.length,
        customerCount: customers.length,
        supplierCount: suppliers.length,
        orderCount: orders.length,
        sizeLabel: '${sizeKb}KB',
      );

      final updated = [meta, ...state].take(20).toList();
      state = updated;
      await _saveHistory(updated);

      // Share the file
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/json')],
        subject: 'ShopIQ Backup — ${_fmtDate(now)}',
        text: 'ShopIQ data backup: ${products.length} products, ${filteredBills.length} bills, ${customers.length} customers.',
      );

      return meta;
    } catch (e) {
      return null;
    }
  }
}

final backupProvider = StateNotifierProvider<BackupNotifier, List<BackupMeta>>(
  (ref) => BackupNotifier(),
);

String _fmtDate(DateTime d) =>
    '${d.day.toString().padLeft(2,'0')}/${d.month.toString().padLeft(2,'0')}/${d.year}';

// ── Backup Screen UI ──────────────────────────────────────────────────────────

class BackupScreen extends ConsumerStatefulWidget {
  const BackupScreen({super.key});

  @override
  ConsumerState<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends ConsumerState<BackupScreen> {
  String _range = 'all';
  bool _backing = false;
  final _emailCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadEmail();
  }

  Future<void> _loadEmail() async {
    final prefs = await SharedPreferences.getInstance();
    _emailCtrl.text = prefs.getString('backup_email') ?? '';
    setState(() {});
  }

  Future<void> _saveEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('backup_email', email);
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _runBackup() async {
    if (_backing) return;
    setState(() => _backing = true);

    final products = ref.read(productsProvider);
    final bills = ref.read(billsProvider);
    final customers = ref.read(customersProvider);
    final suppliers = ref.read(suppliersProvider);
    final orders = ref.read(ordersProvider);

    final meta = await ref.read(backupProvider.notifier).createBackup(
      products: products,
      bills: bills,
      customers: customers,
      suppliers: suppliers,
      orders: orders,
      range: _range,
    );

    if (!mounted) return;
    setState(() => _backing = false);

    if (meta != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Backup created: ${meta.sizeLabel} — ${meta.billCount} bills, ${meta.productCount} products'),
        backgroundColor: AppColors.green600,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Backup failed. Please try again.'),
        backgroundColor: AppColors.red600,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final backups = ref.watch(backupProvider);
    final cs = Theme.of(context).colorScheme;

    // Live counts for preview
    final productCount = ref.watch(productsProvider).length;
    final billCount = ref.watch(billsProvider).length;
    final customerCount = ref.watch(customersProvider).length;
    final supplierCount = ref.watch(suppliersProvider).length;
    final orderCount = ref.watch(ordersProvider).length;

    return Scaffold(
      appBar: AppBar(title: const Text('Backup & Restore')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        children: [
          // ── Status card ─────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.green600, AppColors.green700],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [BoxShadow(color: AppColors.green600.withOpacity(0.3), blurRadius: 12, offset: const Offset(0,4))],
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Icon(Icons.cloud_done_outlined, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                const Text('Backup Status', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                  child: const Text('Local + Export', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                ),
              ]),
              const SizedBox(height: 12),
              Text(
                backups.isEmpty ? 'No backup yet' : 'Last backup: ${_fmtDate(backups.first.date)}',
                style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                backups.isEmpty ? 'Create your first backup now' : '${backups.first.sizeLabel} — ${backups.first.billCount} bills, ${backups.first.productCount} products',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ]),
          ),

          const SizedBox(height: 20),

          // ── Backup email ─────────────────────────────────────────────────
          const _SectionLabel(label: 'Backup Email'),
          TextField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            onChanged: _saveEmail,
            decoration: const InputDecoration(
              hintText: 'your@email.com (for future cloud backup)',
              prefixIcon: Icon(Icons.email_outlined, size: 18),
            ),
          ),

          const SizedBox(height: 20),

          // ── Data range ───────────────────────────────────────────────────
          const _SectionLabel(label: 'Data Range'),
          Wrap(
            spacing: 8,
            children: [
              _RangeChip(label: 'Last 7 days', value: '7days', selected: _range, onTap: (v) => setState(() => _range = v)),
              _RangeChip(label: 'Last 30 days', value: '30days', selected: _range, onTap: (v) => setState(() => _range = v)),
              _RangeChip(label: 'All time', value: 'all', selected: _range, onTap: (v) => setState(() => _range = v)),
            ],
          ),

          const SizedBox(height: 20),

          // ── Data preview ─────────────────────────────────────────────────
          const _SectionLabel(label: 'Data Preview'),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(children: [
              _DataRow(label: 'Products', count: productCount, icon: Icons.inventory_2_outlined, color: AppColors.blue600),
              _DataRow(label: 'Bills', count: billCount, icon: Icons.receipt_long_outlined, color: AppColors.green600),
              _DataRow(label: 'Customers (Khata)', count: customerCount, icon: Icons.people_outlined, color: AppColors.amber600),
              _DataRow(label: 'Suppliers', count: supplierCount, icon: Icons.local_shipping_outlined, color: AppColors.blue600),
              _DataRow(label: 'Orders', count: orderCount, icon: Icons.delivery_dining_outlined, color: AppColors.green600),
            ]),
          ),

          const SizedBox(height: 20),

          // ── Create backup button ─────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _backing ? null : _runBackup,
              icon: _backing
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.backup_outlined, size: 20),
              label: Text(_backing ? 'Creating backup...' : 'Create Backup & Export',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.green600,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),

          const SizedBox(height: 8),

          Text(
            'Backup is exported as JSON. Save to Google Drive, email, or local storage.',
            style: TextStyle(fontSize: 11, color: cs.outline),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 24),

          // ── Backup history ───────────────────────────────────────────────
          if (backups.isNotEmpty) ...[
            const _SectionLabel(label: 'Backup History'),
            ...backups.take(10).map((b) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.green50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.folder_zip_outlined, color: AppColors.green600, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(_fmtDate(b.date),
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  Text('${b.billCount} bills · ${b.productCount} products · ${b.sizeLabel}',
                      style: TextStyle(fontSize: 12, color: cs.outline)),
                ])),
                Text(
                  '${b.date.hour.toString().padLeft(2,'0')}:${b.date.minute.toString().padLeft(2,'0')}',
                  style: TextStyle(fontSize: 12, color: cs.outline),
                ),
              ]),
            )),
          ],

          // ── Restore placeholder ──────────────────────────────────────────
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.amber50,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.amber600.withOpacity(0.3)),
            ),
            child: Row(children: [
              const Icon(Icons.restore_outlined, color: AppColors.amber600),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Restore from Backup', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.amber600)),
                Text('Open the exported JSON file to restore data. Cloud restore coming soon.',
                    style: TextStyle(fontSize: 12, color: cs.outline)),
              ])),
            ]),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 4),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.outline,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _DataRow extends StatelessWidget {
  final String label;
  final int count;
  final IconData icon;
  final Color color;
  const _DataRow({required this.label, required this.count, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 10),
        Expanded(child: Text(label, style: const TextStyle(fontSize: 13))),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text('$count records',
              style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
        ),
      ]),
    );
  }
}

class _RangeChip extends StatelessWidget {
  final String label, value, selected;
  final ValueChanged<String> onTap;
  const _RangeChip({required this.label, required this.value, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isSelected = selected == value;
    return GestureDetector(
      onTap: () => onTap(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.green600 : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? AppColors.green600 : Theme.of(context).colorScheme.outlineVariant),
        ),
        child: Text(label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface,
            )),
      ),
    );
  }
}