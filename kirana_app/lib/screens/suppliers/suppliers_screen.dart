import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../app/theme.dart';
import '../../core/models.dart';
import '../../core/providers.dart';
import '../../core/widgets.dart';

class SuppliersScreen extends ConsumerStatefulWidget {
  const SuppliersScreen({super.key});

  @override
  ConsumerState<SuppliersScreen> createState() => _SuppliersScreenState();
}

class _SuppliersScreenState extends ConsumerState<SuppliersScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  String _filter = 'all'; // 'all' | 'due' | 'overdue'

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allSuppliers = ref.watch(suppliersProvider);
    final notifier = ref.read(suppliersProvider.notifier);

    List<Supplier> list = notifier.search(_query);
    if (_filter == 'due') list = list.where((s) => s.amountDue > 0).toList();
    if (_filter == 'overdue') list = list.where((s) => s.isOverdue).toList();

    final totalDue = allSuppliers.fold<double>(0, (s, x) => s + x.amountDue);
    final overdueCount = notifier.overdueSuppliers.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Suppliers'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Supplier',
            onPressed: () => _showAddEditSheet(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Summary bar ──────────────────────────────────────────────────
          Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.blue600, Color(0xFF1565C0)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(children: [
              Expanded(
                child: _SummaryChip(
                  label: 'Total Due',
                  value: fmtRupee(totalDue),
                  icon: Icons.account_balance_wallet_outlined,
                ),
              ),
              Container(width: 1, height: 40, color: Colors.white24),
              Expanded(
                child: _SummaryChip(
                  label: 'Suppliers',
                  value: '${allSuppliers.length}',
                  icon: Icons.local_shipping_outlined,
                ),
              ),
              Container(width: 1, height: 40, color: Colors.white24),
              Expanded(
                child: _SummaryChip(
                  label: 'Overdue',
                  value: '$overdueCount',
                  icon: Icons.warning_amber_outlined,
                  valueColor: overdueCount > 0 ? AppColors.amber400 : Colors.white,
                ),
              ),
            ]),
          ),

          // ── Search ───────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: 'Search supplier or company...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
              ),
            ),
          ),

          // ── Filter chips ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip(label: 'All (${allSuppliers.length})', value: 'all', selected: _filter, onTap: (v) => setState(() => _filter = v)),
                  const SizedBox(width: 8),
                  _FilterChip(label: 'Has Due', value: 'due', selected: _filter, onTap: (v) => setState(() => _filter = v)),
                  const SizedBox(width: 8),
                  _FilterChip(label: 'Overdue 🔴', value: 'overdue', selected: _filter, onTap: (v) => setState(() => _filter = v)),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),

          // ── List ─────────────────────────────────────────────────────────
          Expanded(
            child: list.isEmpty
                ? EmptyState(
                    icon: Icons.local_shipping_outlined,
                    title: 'No suppliers found',
                    subtitle: _query.isNotEmpty
                        ? 'Try a different search'
                        : 'Tap + to add your first supplier',
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => _SupplierCard(
                      supplier: list[i],
                      onEdit: () => _showAddEditSheet(context, existing: list[i]),
                      onDelete: () => _confirmDelete(context, list[i]),
                      onPayment: () => _showPaymentSheet(context, list[i]),
                      onHistory: () => _showHistory(context, list[i]),
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'add-supplier',
        onPressed: () => _showAddEditSheet(context),
        backgroundColor: AppColors.blue600,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add_outlined),
        label: const Text('Add Supplier', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }

  void _showAddEditSheet(BuildContext context, {Supplier? existing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _AddEditSupplierSheet(
        existing: existing,
        onSave: (s) {
          if (existing == null) {
            ref.read(suppliersProvider.notifier).addSupplier(s);
          } else {
            ref.read(suppliersProvider.notifier).updateSupplier(s);
          }
        },
      ),
    );
  }

  void _showPaymentSheet(BuildContext context, Supplier supplier) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _PaymentSheet(
        supplier: supplier,
        onPay: (amount, note) {
          ref.read(suppliersProvider.notifier).recordPayment(supplier.id, amount, note);
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Payment of ${fmtRupee(amount)} recorded'),
            backgroundColor: AppColors.green600,
            behavior: SnackBarBehavior.floating,
          ));
        },
      ),
    );
  }

  void _showHistory(BuildContext context, Supplier supplier) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _TransactionHistorySheet(supplier: supplier),
    );
  }

  void _confirmDelete(BuildContext context, Supplier supplier) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Supplier'),
        content: Text('Remove ${supplier.name} from your supplier list?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(suppliersProvider.notifier).deleteSupplier(supplier.id);
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.red600),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// ── Supplier Card ─────────────────────────────────────────────────────────────

class _SupplierCard extends StatelessWidget {
  final Supplier supplier;
  final VoidCallback onEdit, onDelete, onPayment, onHistory;

  const _SupplierCard({
    required this.supplier,
    required this.onEdit,
    required this.onDelete,
    required this.onPayment,
    required this.onHistory,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isOverdue = supplier.isOverdue;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: isOverdue
            ? Border.all(color: AppColors.red600.withOpacity(0.4), width: 1.5)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.blue50,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  supplier.name[0].toUpperCase(),
                  style: const TextStyle(
                      color: AppColors.blue600,
                      fontSize: 18,
                      fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Flexible(
                      child: Text(supplier.name,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                          overflow: TextOverflow.ellipsis),
                    ),
                    if (isOverdue) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.red600.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('OVERDUE',
                            style: TextStyle(fontSize: 9, color: AppColors.red600, fontWeight: FontWeight.w800)),
                      ),
                    ],
                  ]),
                  if (supplier.companyName != null)
                    Text(supplier.companyName!,
                        style: TextStyle(fontSize: 12, color: cs.outline),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                ]),
              ),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(
                  fmtRupee(supplier.amountDue),
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: supplier.amountDue > 0 ? AppColors.red600 : AppColors.green600,
                  ),
                ),
                Text('due', style: TextStyle(fontSize: 11, color: cs.outline)),
              ]),
            ]),
          ),

          // Meta row
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
            child: Row(children: [
              Icon(Icons.phone_outlined, size: 13, color: cs.outline),
              const SizedBox(width: 4),
              Text(supplier.phone, style: TextStyle(fontSize: 12, color: cs.outline)),
              if (supplier.lastSupplyDate != null) ...[
                const SizedBox(width: 14),
                Icon(Icons.calendar_today_outlined, size: 13, color: cs.outline),
                const SizedBox(width: 4),
                Text(fmtDay(supplier.lastSupplyDate!),
                    style: TextStyle(fontSize: 12, color: cs.outline)),
              ],
            ]),
          ),

          if (supplier.productNotes != null && supplier.productNotes!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
              child: Row(children: [
                Icon(Icons.inventory_2_outlined, size: 13, color: cs.outline),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(supplier.productNotes!,
                      style: TextStyle(fontSize: 12, color: cs.outline),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
              ]),
            ),

          // Action row
          Container(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: cs.outlineVariant.withOpacity(0.5))),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: Row(children: [
              _ActionBtn(icon: Icons.phone, label: 'Call', color: AppColors.green600, onTap: () => _call(supplier.phone)),
              _ActionBtn(icon: Icons.chat, label: 'WhatsApp', color: AppColors.waGreen, onTap: () => _whatsapp(supplier)),
              _ActionBtn(icon: Icons.history, label: 'History', color: AppColors.blue600, onTap: onHistory),
              if (supplier.amountDue > 0)
                _ActionBtn(icon: Icons.payments_outlined, label: 'Pay', color: AppColors.amber600, onTap: onPayment),
              const Spacer(),
              IconButton(
                icon: Icon(Icons.edit_outlined, size: 18, color: cs.outline),
                onPressed: onEdit,
                tooltip: 'Edit',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.red600),
                onPressed: onDelete,
                tooltip: 'Delete',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  Future<void> _call(String phone) async {
    final url = Uri.parse('tel:$phone');
    if (await canLaunchUrl(url)) await launchUrl(url);
  }

  Future<void> _whatsapp(Supplier s) async {
    final text = Uri.encodeComponent('Hello ${s.name} ji, regarding our account balance of ${fmtRupee(s.amountDue)}.');
    final url = Uri.parse('https://wa.me/91${s.phone}?text=$text');
    if (await canLaunchUrl(url)) await launchUrl(url, mode: LaunchMode.externalApplication);
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionBtn({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 14, color: color),
      label: Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}

// ── Add/Edit Supplier Sheet ───────────────────────────────────────────────────

class _AddEditSupplierSheet extends StatefulWidget {
  final Supplier? existing;
  final ValueChanged<Supplier> onSave;
  const _AddEditSupplierSheet({this.existing, required this.onSave});

  @override
  State<_AddEditSupplierSheet> createState() => _AddEditSupplierSheetState();
}

class _AddEditSupplierSheetState extends State<_AddEditSupplierSheet> {
  late final TextEditingController _name, _phone, _company, _due, _notes;

  @override
  void initState() {
    super.initState();
    final s = widget.existing;
    _name = TextEditingController(text: s?.name ?? '');
    _phone = TextEditingController(text: s?.phone ?? '');
    _company = TextEditingController(text: s?.companyName ?? '');
    _due = TextEditingController(text: s?.amountDue != null && s!.amountDue > 0 ? s.amountDue.toStringAsFixed(0) : '');
    _notes = TextEditingController(text: s?.productNotes ?? '');
  }

  @override
  void dispose() {
    _name.dispose(); _phone.dispose(); _company.dispose(); _due.dispose(); _notes.dispose();
    super.dispose();
  }

  void _save() {
    if (_name.text.trim().isEmpty || _phone.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Name and phone are required'),
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    final supplier = Supplier(
      id: widget.existing?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: _name.text.trim(),
      phone: _phone.text.trim(),
      companyName: _company.text.trim().isEmpty ? null : _company.text.trim(),
      amountDue: double.tryParse(_due.text) ?? widget.existing?.amountDue ?? 0,
      lastSupplyDate: widget.existing?.lastSupplyDate,
      productNotes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      transactions: widget.existing?.transactions ?? [],
    );
    widget.onSave(supplier);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Row(children: [
            Text(widget.existing == null ? 'Add Supplier' : 'Edit Supplier',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const Spacer(),
            IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
          ]),
          const SizedBox(height: 16),
          _Field(ctrl: _name, label: 'Supplier Name *', icon: Icons.person_outline, keyboardType: TextInputType.name),
          const SizedBox(height: 12),
          _Field(ctrl: _phone, label: 'Mobile Number *', icon: Icons.phone_outlined, keyboardType: TextInputType.phone),
          const SizedBox(height: 12),
          _Field(ctrl: _company, label: 'Company / Shop Name', icon: Icons.store_outlined),
          const SizedBox(height: 12),
          _Field(ctrl: _due, label: 'Current Due (₹)', icon: Icons.account_balance_wallet_outlined, keyboardType: TextInputType.number),
          const SizedBox(height: 12),
          _Field(ctrl: _notes, label: 'Product Notes (e.g. Atta, Dal)', icon: Icons.inventory_2_outlined, maxLines: 2),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _save,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.blue600,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(widget.existing == null ? 'Add Supplier' : 'Save Changes',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            ),
          ),
        ]),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final int maxLines;

  const _Field({
    required this.ctrl,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 18),
      ),
    );
  }
}

// ── Payment Sheet ─────────────────────────────────────────────────────────────

class _PaymentSheet extends StatefulWidget {
  final Supplier supplier;
  final void Function(double amount, String note) onPay;
  const _PaymentSheet({required this.supplier, required this.onPay});

  @override
  State<_PaymentSheet> createState() => _PaymentSheetState();
}

class _PaymentSheetState extends State<_PaymentSheet> {
  final _amtCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  @override
  void dispose() { _amtCtrl.dispose(); _noteCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Record Payment', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text('Due: ${fmtRupee(widget.supplier.amountDue)} to ${widget.supplier.name}',
            style: const TextStyle(fontSize: 13, color: AppColors.red600)),
        const SizedBox(height: 20),
        TextField(
          controller: _amtCtrl,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Amount Paid (₹)',
            prefixIcon: Icon(Icons.payments_outlined, size: 18),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _noteCtrl,
          decoration: const InputDecoration(
            labelText: 'Note (optional)',
            prefixIcon: Icon(Icons.note_outlined, size: 18),
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () {
              final amt = double.tryParse(_amtCtrl.text);
              if (amt == null || amt <= 0) return;
              widget.onPay(amt, _noteCtrl.text.trim().isEmpty ? 'Payment' : _noteCtrl.text.trim());
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.green600,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: const Text('Confirm Payment', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          ),
        ),
      ]),
    );
  }
}

// ── Transaction History Sheet ─────────────────────────────────────────────────

class _TransactionHistorySheet extends StatelessWidget {
  final Supplier supplier;
  const _TransactionHistorySheet({required this.supplier});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final txns = supplier.transactions.reversed.toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.92,
      minChildSize: 0.4,
      expand: false,
      builder: (_, ctrl) => Column(children: [
        Container(
          margin: const EdgeInsets.only(top: 12),
          width: 40, height: 4,
          decoration: BoxDecoration(color: cs.outlineVariant, borderRadius: BorderRadius.circular(4)),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${supplier.name} — History',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              Text('Balance due: ${fmtRupee(supplier.amountDue)}',
                  style: TextStyle(fontSize: 13,
                      color: supplier.amountDue > 0 ? AppColors.red600 : AppColors.green600,
                      fontWeight: FontWeight.w600)),
            ])),
            IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
          ]),
        ),
        const Divider(height: 1),
        Expanded(
          child: txns.isEmpty
              ? const Center(child: Text('No transactions yet'))
              : ListView.separated(
                  controller: ctrl,
                  padding: const EdgeInsets.all(16),
                  itemCount: txns.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final tx = txns[i];
                    final isPayment = tx.type == 'payment';
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isPayment ? AppColors.green50 : cs.surfaceContainerHighest.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isPayment ? AppColors.green600.withOpacity(0.2) : cs.outlineVariant.withOpacity(0.3),
                        ),
                      ),
                      child: Row(children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isPayment ? AppColors.green600 : AppColors.blue600,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isPayment ? Icons.arrow_upward : Icons.arrow_downward,
                            color: Colors.white, size: 14,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(tx.note, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          Text(fmtDate(tx.date), style: TextStyle(fontSize: 11, color: cs.outline)),
                        ])),
                        Text(
                          '${isPayment ? '+' : '-'}${fmtRupee(tx.amount)}',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: isPayment ? AppColors.green600 : AppColors.red600,
                          ),
                        ),
                      ]),
                    );
                  },
                ),
        ),
      ]),
    );
  }
}

// ── Small helpers ─────────────────────────────────────────────────────────────

class _SummaryChip extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color? valueColor;
  const _SummaryChip({required this.label, required this.value, required this.icon, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Icon(icon, color: Colors.white70, size: 18),
      const SizedBox(height: 4),
      Text(value, style: TextStyle(color: valueColor ?? Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
      Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10)),
    ]);
  }
}

class _FilterChip extends StatelessWidget {
  final String label, value, selected;
  final ValueChanged<String> onTap;
  const _FilterChip({required this.label, required this.value, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isSelected = selected == value;
    return GestureDetector(
      onTap: () => onTap(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.blue600 : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? AppColors.blue600 : Theme.of(context).colorScheme.outlineVariant),
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