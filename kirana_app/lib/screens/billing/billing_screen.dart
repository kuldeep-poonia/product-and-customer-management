import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../app/theme.dart';
import '../../core/app_constants.dart';
import '../../core/models.dart';
import '../../core/providers.dart';
import '../../core/widgets.dart';

class BillingScreen extends ConsumerStatefulWidget {
  const BillingScreen({super.key});

  @override
  ConsumerState<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends ConsumerState<BillingScreen> {
  final _searchCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _discountCtrl = TextEditingController();

  // Local search state — not a global provider so closing billing
  // doesn't bleed the query into other screens.
  String _searchQuery = '';

  bool _saving = false;

  // ── Barcode scan ─────────────────────────────────────────────────────────
  Future<void> _openScanner() async {
    final code = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const _BarcodeScannerScreen()),
    );
    if (code == null || !mounted) return;
    _addItemByBarcode(code);
  }

  void _addItemByBarcode(String barcode) {
    final products = ref.read(productsProvider);
    // Match by barcode field or product id as fallback
    final match = products.where((p) => p.id == barcode).firstOrNull;
    if (match != null) {
      ref.read(billingProvider.notifier).addItem(match);
      HapticFeedback.mediumImpact();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Added: ${match.name}'),
        backgroundColor: AppColors.green600,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 1),
      ));
    } else {
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Product not found for barcode: $barcode'),
        backgroundColor: AppColors.red600,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  @override
  void dispose() {
    // Always reset shared providers when leaving billing so the next
    // bill doesn't inherit a stale payment mode.
    ref.read(paymentModeProvider.notifier).state = PaymentMode.cash;
    _searchCtrl.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _discountCtrl.dispose();
    super.dispose();
  }

  double get _subtotal => ref.read(billingProvider.notifier).subtotal;

  // Clamp discount so total can never go negative.
  double get _safeDiscount {
    final d = double.tryParse(_discountCtrl.text) ?? 0;
    return d.clamp(0, _subtotal);
  }

  double get _total => (_subtotal - _safeDiscount).clamp(0, double.infinity);

  Future<void> _saveBill() async {
    final items = ref.read(billingProvider);
    if (items.isEmpty) return;

    // Validate stock for every item before touching any state.
    final stockError = ref.read(productsProvider.notifier).validateCartStock(items);
    if (stockError != null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Cannot save: $stockError'),
        backgroundColor: AppColors.red600,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    // Guard against double-tap — _saving is set before any async work.
    if (_saving) return;
    setState(() => _saving = true);

    final mode = ref.read(paymentModeProvider);
    final bill = Bill(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      customerName: _nameCtrl.text.trim().isEmpty ? null : _nameCtrl.text.trim(),
      customerPhone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      items: items,
      paymentMode: mode,
      discount: _safeDiscount,
      createdAt: DateTime.now(),
      isPaid: mode != PaymentMode.udhaar,
    );

    ref.read(billsProvider.notifier).addBill(bill);

    // Deduct stock only after the bill is confirmed saved.
    final prodNotifier = ref.read(productsProvider.notifier);
    for (final item in items) {
      prodNotifier.updateStock(item.product.id, -item.qty);
    }

    // Link udhaar to existing customer ledger if we can find them by name.
    if (mode == PaymentMode.udhaar && bill.customerName != null) {
      final customers = ref.read(customersProvider);
      final match = customers.where(
        (c) => c.name.toLowerCase() == bill.customerName!.toLowerCase(),
      ).firstOrNull;
      if (match != null) {
        ref.read(customersProvider.notifier).addDebit(
          match.id,
          bill.total,
          'Bill #${bill.id.substring(bill.id.length - 4)}',
        );
      }
    }

    ref.read(billingProvider.notifier).clear();
    ref.read(paymentModeProvider.notifier).state = PaymentMode.cash;

    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;
    setState(() => _saving = false);
    _showBillSavedSheet(context, bill);
  }

  void _showBillSavedSheet(BuildContext context, Bill bill) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _BillSavedSheet(
        bill: bill,
        onDone: () {
          Navigator.pop(context);
          context.pop();
        },
      ),
    );
  }

  void _clearAndPop() {
    ref.read(billingProvider.notifier).clear();
    ref.read(paymentModeProvider.notifier).state = PaymentMode.cash;
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(billingProvider);
    final payMode = ref.watch(paymentModeProvider);
    final cs = Theme.of(context).colorScheme;

    final filtered = ref.read(productsProvider.notifier).search(_searchQuery);
    final subtotal = ref.read(billingProvider.notifier).subtotal;
    final discount = _safeDiscount;
    final total = _total;

    // Warn user if typed discount was clamped.
    final typedDiscount = double.tryParse(_discountCtrl.text) ?? 0;
    final discountClamped = typedDiscount > subtotal && subtotal > 0;

    return PopScope(
      // Intercept system back / swipe-back so the cart is always cleared.
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _clearAndPop();
      },
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          title: const Text('Quick Bill'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _clearAndPop,
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.qr_code_scanner),
              tooltip: 'Scan Barcode',
              onPressed: _openScanner,
            ),
            if (items.isNotEmpty)
              TextButton(
                onPressed: () => ref.read(billingProvider.notifier).clear(),
                child: const Text('Clear'),
              ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
            // Search bar — uses local state, no global provider.
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (v) => setState(() => _searchQuery = v),
                decoration: InputDecoration(
                  hintText: 'Search item... (e.g. Atta, Tata)',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                ),
                textInputAction: TextInputAction.search,
              ),
            ),

            // Search results dropdown.
            if (_searchQuery.isNotEmpty)
              Container(
                constraints: const BoxConstraints(maxHeight: 220),
                margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: filtered.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(20),
                        child: Center(child: Text('No items found')),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) =>
                            const Divider(height: 1, indent: 56),
                        itemBuilder: (_, i) => ProductListTile(
                          product: filtered[i],
                          trailing: IconButton(
                            icon: Icon(Icons.add_circle,
                                color: cs.primary, size: 28),
                            onPressed: () {
                              ref
                                  .read(billingProvider.notifier)
                                  .addItem(filtered[i]);
                              HapticFeedback.lightImpact();
                            },
                          ),
                          onTap: () {
                            ref
                                .read(billingProvider.notifier)
                                .addItem(filtered[i]);
                            HapticFeedback.lightImpact();
                          },
                        ),
                      ),
              ),

            // Cart item list.
            Expanded(
              child: items.isEmpty
                  ? const EmptyState(
                      icon: Icons.receipt_long_outlined,
                      title: 'Bill is empty',
                      subtitle: 'Search and add items above',
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, i) => _BillItemRow(item: items[i]),
                    ),
            ),

            // Footer with discount, payment mode, and save.
            if (items.isNotEmpty)
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(20)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 12,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: Column(children: [
                  // Customer name + phone.
                  Row(children: [
                    Expanded(
                      child: TextField(
                        controller: _nameCtrl,
                        decoration: const InputDecoration(
                          hintText: 'Customer name',
                          prefixIcon:
                              Icon(Icons.person_outline, size: 18),
                        ),
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 130,
                      child: TextField(
                        controller: _phoneCtrl,
                        decoration: const InputDecoration(
                          hintText: 'Mobile',
                          prefixIcon: Icon(Icons.phone_outlined, size: 18),
                        ),
                        keyboardType: TextInputType.phone,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 10),

                  // Discount row with clamp warning.
                  Row(children: [
                    const Icon(Icons.discount_outlined,
                        size: 18, color: AppColors.amber600),
                    const SizedBox(width: 8),
                    const Text('Discount',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w500)),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 90,
                      child: TextField(
                        controller: _discountCtrl,
                        onChanged: (_) => setState(() {}),
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          hintText: '₹0',
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                        ),
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    if (discountClamped) ...[
                      const SizedBox(width: 8),
                      Text(
                        'Max: ${fmtRupee(subtotal)}',
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.red600),
                      ),
                    ],
                  ]),
                  const SizedBox(height: 12),

                  // Payment mode chips.
                  Row(children: [
                    const Text('Pay via:',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w500)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: PaymentMode.values.map((m) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: _PayModeChip(
                              mode: m,
                              selected: payMode == m,
                              onTap: () => ref
                                  .read(paymentModeProvider.notifier)
                                  .state = m,
                            ),
                          )).toList(),
                        ),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 14),

                  // Total and save button.
                  Row(children: [
                    Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (discount > 0)
                            Text(
                              'Subtotal: ${fmtRupee(subtotal)}',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: cs.outline,
                                  decoration: TextDecoration.lineThrough),
                            ),
                          Text(
                            'Total: ${fmtRupee(total)}',
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.w900),
                          ),
                        ]),
                    const Spacer(),
                    FilledButton.icon(
                      onPressed: _saving ? null : _saveBill,
                      icon: _saving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.check, size: 18),
                      label: Text(_saving ? 'Saving...' : 'Save Bill'),
                      style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 14)),
                    ),
                  ]),
                ]),
            ),
          ],
          ),
        ),
      ),
    );
  }
}

// Quantity row for each cart item.
class _BillItemRow extends ConsumerWidget {
  final BillItem item;
  const _BillItemRow({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(item.product.name,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            Text(
              '${fmtRupee(item.unitPrice)} / ${item.product.unit}',
              style: TextStyle(fontSize: 12, color: cs.outline),
            ),
          ]),
        ),
        const SizedBox(width: 8),
        QtyControl(
          qty: item.qty,
          onDec: () => ref
              .read(billingProvider.notifier)
              .updateQty(item.product.id, item.qty - 1),
          onInc: () => ref
              .read(billingProvider.notifier)
              .updateQty(item.product.id, item.qty + 1),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 64,
          child: Text(fmtRupee(item.total),
              textAlign: TextAlign.right,
              style:
                  const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
        ),
        IconButton(
          icon: Icon(Icons.delete_outline, color: cs.error, size: 18),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          onPressed: () =>
              ref.read(billingProvider.notifier).removeItem(item.product.id),
        ),
      ]),
    );
  }
}

class _PayModeChip extends StatelessWidget {
  final PaymentMode mode;
  final bool selected;
  final VoidCallback onTap;

  const _PayModeChip(
      {required this.mode, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (mode) {
      PaymentMode.cash => ('Cash', AppColors.green600),
      PaymentMode.upi => ('UPI', AppColors.blue600),
      PaymentMode.udhaar => ('Udhaar', AppColors.red600),
      PaymentMode.mixed => ('Mixed', AppColors.amber600),
    };
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color : color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(selected ? 0 : 0.3)),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : color)),
      ),
    );
  }
}

class _BillSavedSheet extends StatelessWidget {
  final Bill bill;
  final VoidCallback onDone;

  const _BillSavedSheet({required this.bill, required this.onDone});

  String _buildWhatsAppText() {
    final sb = StringBuffer();
    sb.writeln('*Bill from ${AppConstants.defaultShopName}*');
    sb.writeln('Date: ${fmtDate(bill.createdAt)}');
    sb.writeln('');
    for (final item in bill.items) {
      sb.writeln('${item.product.name} x${item.qty} = ${fmtRupee(item.total)}');
    }
    sb.writeln('');
    if (bill.discount > 0) {
      sb.writeln('Discount: -${fmtRupee(bill.discount)}');
    }
    sb.writeln('*Total: ${fmtRupee(bill.total)}*');
    sb.writeln('Payment: ${bill.paymentMode.name.toUpperCase()}');
    sb.writeln('');
    sb.writeln('Thank you! - ${AppConstants.appName}');
    return sb.toString();
  }

  Future<void> _sendWhatsApp(BuildContext context) async {
    final text = Uri.encodeComponent(_buildWhatsAppText());
    final phone = bill.customerPhone ?? '';
    final url = Uri.parse(phone.isNotEmpty
        ? 'https://wa.me/91$phone?text=$text'
        : 'https://wa.me/?text=$text');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: cs.outlineVariant,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 20),
        Container(
          width: 64,
          height: 64,
          decoration:
              const BoxDecoration(color: AppColors.green50, shape: BoxShape.circle),
          alignment: Alignment.center,
          child: const Icon(Icons.check_circle,
              color: AppColors.green600, size: 40),
        ),
        const SizedBox(height: 12),
        const Text('Bill Saved!',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text('${bill.itemCount} items  ·  ${fmtRupee(bill.total)}',
            style: TextStyle(color: cs.outline, fontSize: 14)),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: bill.items
                .map((item) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(children: [
                        Expanded(
                            child: Text('${item.product.name} × ${item.qty}',
                                style: const TextStyle(fontSize: 13))),
                        Text(fmtRupee(item.total),
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w600)),
                      ]),
                    ))
                .toList(),
          ),
        ),
        const SizedBox(height: 20),
        Row(children: [
          Expanded(
            child: WhatsAppButton(
              label: 'Send on WhatsApp',
              onTap: () => _sendWhatsApp(context),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton(
                onPressed: onDone, child: const Text('New Bill')),
          ),
        ]),
      ]),
    );
  }
}

// ── Barcode Scanner Screen ─────────────────────────────────────────────────────
// Pushed from billing AppBar. Returns the scanned barcode string via Navigator.pop.

class _BarcodeScannerScreen extends StatefulWidget {
  const _BarcodeScannerScreen();

  @override
  State<_BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<_BarcodeScannerScreen> {
  final MobileScannerController _ctrl = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
    torchEnabled: false,
  );
  bool _torchOn = false;
  bool _scanned = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_scanned) return;
    final code = capture.barcodes.firstOrNull?.rawValue;
    if (code == null) return;
    _scanned = true;
    HapticFeedback.mediumImpact();
    Navigator.pop(context, code);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Scan Barcode'),
        actions: [
          IconButton(
            icon: Icon(_torchOn ? Icons.flash_on : Icons.flash_off, color: Colors.white),
            onPressed: () {
              _ctrl.toggleTorch();
              setState(() => _torchOn = !_torchOn);
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Camera view
          MobileScanner(
            controller: _ctrl,
            onDetect: _onDetect,
          ),

          // Scan overlay
          Center(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.green600, width: 3),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Stack(
                children: [
                  // Corner decorations
                  for (final align in [
                    Alignment.topLeft,
                    Alignment.topRight,
                    Alignment.bottomLeft,
                    Alignment.bottomRight,
                  ])
                    Align(
                      alignment: align,
                      child: Container(
                        width: 28, height: 28,
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(
                              color: AppColors.green600,
                              width: align.y < 0 ? 4 : 0,
                            ),
                            bottom: BorderSide(
                              color: AppColors.green600,
                              width: align.y > 0 ? 4 : 0,
                            ),
                            left: BorderSide(
                              color: AppColors.green600,
                              width: align.x < 0 ? 4 : 0,
                            ),
                            right: BorderSide(
                              color: AppColors.green600,
                              width: align.x > 0 ? 4 : 0,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Instruction text
          Positioned(
            bottom: 80,
            left: 0, right: 0,
            child: Column(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Point camera at product barcode',
                  style: TextStyle(color: Colors.white, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}