import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../app/theme.dart';
import '../../core/app_constants.dart';
import '../../core/models.dart';
import '../../core/providers.dart';
import '../../core/widgets.dart';

class KhataScreen extends ConsumerStatefulWidget {
  const KhataScreen({super.key});

  @override
  ConsumerState<KhataScreen> createState() => _KhataScreenState();
}

class _KhataScreenState extends ConsumerState<KhataScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final customers = ref.watch(customersProvider);
    final totalDue = ref.read(customersProvider.notifier).totalPendingUdhaar;
    final cs = Theme.of(context).colorScheme;

    final filtered = _query.isEmpty
        ? customers
        : customers.where((c) => c.name.toLowerCase().contains(_query.toLowerCase()) || c.phone.contains(_query)).toList();

    final sorted = [...filtered]..sort((a, b) => b.totalDue.compareTo(a.totalDue));

    return Scaffold(
      appBar: AppBar(
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Khata / Udhaar'),
          Text('Total Due: ${fmtRupee(totalDue)}', style: const TextStyle(fontSize: 12, color: AppColors.red600, fontWeight: FontWeight.w600)),
        ]),
        actions: [
          IconButton(icon: const Icon(Icons.person_add_outlined), onPressed: () => _showAddCustomerDialog(context), tooltip: 'Add Customer'),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: TextField(
            controller: _searchCtrl,
            onChanged: (v) => setState(() => _query = v),
            decoration: InputDecoration(
              hintText: 'Search customer...',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _query.isNotEmpty ? IconButton(icon: const Icon(Icons.close, size: 18), onPressed: () { _searchCtrl.clear(); setState(() => _query = ''); }) : null,
            ),
          ),
        ),
        Expanded(
          child: sorted.isEmpty
              ? const EmptyState(icon: Icons.book_outlined, title: 'No customers found', subtitle: 'Add a customer to start tracking udhaar')
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: sorted.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) => _CustomerKhataCard(customer: sorted[i]),
                ),
        ),
      ]),
    );
  }

  void _showAddCustomerDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Customer'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name'), autofocus: true),
          const SizedBox(height: 12),
          TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Mobile'), keyboardType: TextInputType.phone),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(onPressed: () { Navigator.pop(ctx); }, child: const Text('Add')),
        ],
      ),
    );
  }
}

// ─── CUSTOMER KHATA CARD ─────────────────────────────────────────────────────

class _CustomerKhataCard extends ConsumerWidget {
  final Customer customer;
  const _CustomerKhataCard({required this.customer});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final due = customer.totalDue;
    final dueColor = due > 0 ? AppColors.red600 : AppColors.green600;

    return GestureDetector(
      onTap: () => _showKhataDetail(context, ref),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(14),
          border: customer.isOverdue ? Border.all(color: AppColors.red400.withOpacity(0.4)) : null,
        ),
        child: Row(children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: due > 0 ? AppColors.red50 : AppColors.green50,
            child: Text(customer.name[0], style: TextStyle(color: dueColor, fontWeight: FontWeight.w800, fontSize: 16)),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(customer.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14))),
              if (customer.isOverdue) const AlertChip(label: 'Overdue', color: AppColors.red600, icon: Icons.warning_amber),
            ]),
            const SizedBox(height: 2),
            Text(customer.phone, style: TextStyle(fontSize: 12, color: cs.outline)),
            Text('Last: ${fmtDay(customer.lastActivity)}', style: TextStyle(fontSize: 11, color: cs.outline)),
          ])),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(fmtRupee(due.abs()), style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: dueColor)),
            Text(due > 0 ? 'to collect' : due < 0 ? 'advance' : 'settled', style: TextStyle(fontSize: 11, color: dueColor)),
            Row(mainAxisSize: MainAxisSize.min, children: [
              IconButton(icon: const Icon(Icons.chat, color: AppColors.waGreen, size: 20), padding: EdgeInsets.zero, constraints: const BoxConstraints(), onPressed: () => _sendReminder(customer)),
              const SizedBox(width: 4),
              IconButton(icon: Icon(Icons.phone, color: cs.primary, size: 20), padding: EdgeInsets.zero, constraints: const BoxConstraints(), onPressed: () => _call(customer.phone)),
            ]),
          ]),
        ]),
      ),
    );
  }

  Future<void> _sendReminder(Customer c) async {
    final text = Uri.encodeComponent('Namaste ${c.name} ji\n\nAapka ${fmtRupee(c.totalDue)} baaki hai *${AppConstants.defaultShopName}* mein.\n\nKripya jald se payment karein. Dhanyawad! - ${AppConstants.appName}');
    final url = Uri.parse('https://wa.me/91${c.phone}?text=$text');
    if (await canLaunchUrl(url)) await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  Future<void> _call(String phone) async {
    final url = Uri.parse('tel:$phone');
    if (await canLaunchUrl(url)) await launchUrl(url);
  }

  void _showKhataDetail(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _KhataDetailSheet(customer: customer, ref: ref),
    );
  }
}

// ─── KHATA DETAIL SHEET ──────────────────────────────────────────────────────

class _KhataDetailSheet extends StatefulWidget {
  final Customer customer;
  final WidgetRef ref;
  const _KhataDetailSheet({required this.customer, required this.ref});

  @override
  State<_KhataDetailSheet> createState() => _KhataDetailSheetState();
}

class _KhataDetailSheetState extends State<_KhataDetailSheet> {
  final _amtCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  @override
  void dispose() { _amtCtrl.dispose(); _noteCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final due = widget.customer.totalDue;
    final dueColor = due > 0 ? AppColors.red600 : AppColors.green600;
    final sorted = [...widget.customer.khata]..sort((a, b) => b.date.compareTo(a.date));

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      expand: false,
      builder: (_, ctrl) => Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Column(children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: cs.outlineVariant, borderRadius: BorderRadius.circular(4))),
            const SizedBox(height: 16),
            Row(children: [
              CircleAvatar(radius: 24, backgroundColor: AppColors.green50, child: Text(widget.customer.name[0], style: const TextStyle(color: AppColors.green600, fontWeight: FontWeight.w800, fontSize: 20))),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(widget.customer.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                Text(widget.customer.phone, style: TextStyle(color: cs.outline, fontSize: 13)),
              ])),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(fmtRupee(due.abs()), style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: dueColor)),
                Text(due > 0 ? 'to collect' : 'advance', style: TextStyle(fontSize: 12, color: dueColor)),
              ]),
            ]),
            const SizedBox(height: 16),

            // Add payment row
            Row(children: [
              Expanded(child: TextField(controller: _amtCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: '₹ Amount', prefixText: '₹ '))),
              const SizedBox(width: 8),
              Expanded(child: TextField(controller: _noteCtrl, decoration: const InputDecoration(hintText: 'Note (optional)'))),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: () {
                  final amt = double.tryParse(_amtCtrl.text);
                  if (amt == null || amt <= 0) return;
                  widget.ref.read(customersProvider.notifier).addPayment(widget.customer.id, amt, _noteCtrl.text.isEmpty ? 'Payment received' : _noteCtrl.text);
                  _amtCtrl.clear(); _noteCtrl.clear();
                  Navigator.pop(context);
                },
                style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16)),
                child: const Text('Add\nPayment', textAlign: TextAlign.center, style: TextStyle(fontSize: 12)),
              ),
            ]),
            const SizedBox(height: 16),
            const Divider(),
          ]),
        ),
        Expanded(
          child: ListView.separated(
            controller: ctrl,
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            itemCount: sorted.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) {
              final e = sorted[i];
              final isDebit = e.type == 'debit';
              return Row(children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(color: isDebit ? AppColors.red50 : AppColors.green50, shape: BoxShape.circle),
                  alignment: Alignment.center,
                  child: Icon(isDebit ? Icons.arrow_upward : Icons.arrow_downward, size: 16, color: isDebit ? AppColors.red600 : AppColors.green600),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(e.note, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                  Text(fmtDate(e.date), style: TextStyle(fontSize: 11, color: cs.outline)),
                ])),
                Text('${isDebit ? '+' : '-'}${fmtRupee(e.amount)}', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: isDebit ? AppColors.red600 : AppColors.green600)),
              ]);
            },
          ),
        ),
      ]),
    );
  }
}
