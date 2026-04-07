import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../app/theme.dart';
import 'models.dart';

final _rupee = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

String fmtRupee(double v) => _rupee.format(v);
String fmtDate(DateTime d) => DateFormat('d MMM, hh:mm a').format(d);
String fmtDay(DateTime d) => DateFormat('EEE, d MMM').format(d);

// ─── STAT CARD ──────────────────────────────────────────────────────────────

class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final VoidCallback? onTap;
  final String? subtitle;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    this.onTap,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(10)),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                if (onTap != null)
                  Icon(Icons.arrow_forward_ios, size: 12, color: cs.outline),
              ],
            ),
            const SizedBox(height: 12),
            Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: cs.onSurface)),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 12, color: cs.onSurface.withOpacity(0.6))),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(subtitle!, style: TextStyle(fontSize: 11, color: cs.primary, fontWeight: FontWeight.w600)),
            ]
          ],
        ),
      ),
    );
  }
}

// ─── SECTION HEADER ─────────────────────────────────────────────────────────

class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const SectionHeader({super.key, required this.title, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        if (actionLabel != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 0), tapTargetSize: MaterialTapTargetSize.shrinkWrap),
            child: Text(actionLabel!, style: TextStyle(fontSize: 13, color: cs.primary, fontWeight: FontWeight.w600)),
          ),
      ],
    );
  }
}

// ─── ALERT CHIP ─────────────────────────────────────────────────────────────

class AlertChip extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;

  const AlertChip({super.key, required this.label, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 5),
        Text(label, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

// ─── PAYMENT MODE BADGE ─────────────────────────────────────────────────────

class PaymentBadge extends StatelessWidget {
  final PaymentMode mode;
  const PaymentBadge({super.key, required this.mode});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (mode) {
      PaymentMode.cash => ('CASH', AppColors.green600),
      PaymentMode.upi => ('UPI', AppColors.blue600),
      PaymentMode.udhaar => ('UDHAAR', AppColors.red400),
      PaymentMode.mixed => ('MIXED', AppColors.amber600),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
    );
  }
}

// ─── QTY CONTROL ────────────────────────────────────────────────────────────

class QtyControl extends StatelessWidget {
  final int qty;
  final VoidCallback onInc;
  final VoidCallback onDec;

  const QtyControl({super.key, required this.qty, required this.onInc, required this.onDec});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: cs.outline.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        _btn(context, Icons.remove, onDec, qty <= 1 ? cs.outline : cs.error),
        Container(
          width: 36,
          alignment: Alignment.center,
          child: Text('$qty', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
        ),
        _btn(context, Icons.add, onInc, cs.primary),
      ]),
    );
  }

  Widget _btn(BuildContext ctx, IconData icon, VoidCallback fn, Color color) {
    return InkWell(
      onTap: fn,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }
}

// ─── WHATSAPP BUTTON ────────────────────────────────────────────────────────

class WhatsAppButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const WhatsAppButton({super.key, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: const Icon(Icons.chat, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.waGreen,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        elevation: 0,
      ),
    );
  }
}

// ─── EMPTY STATE ────────────────────────────────────────────────────────────

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const EmptyState({super.key, required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, size: 64, color: cs.outline.withOpacity(0.5)),
        const SizedBox(height: 16),
        Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: cs.onSurface.withOpacity(0.7))),
        const SizedBox(height: 6),
        Text(subtitle, style: TextStyle(fontSize: 13, color: cs.outline), textAlign: TextAlign.center),
      ]),
    );
  }
}

// ─── LOW STOCK BADGE ────────────────────────────────────────────────────────

class LowStockBadge extends StatelessWidget {
  const LowStockBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: AppColors.red600, borderRadius: BorderRadius.circular(6)),
      child: const Text('LOW', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)),
    );
  }
}

// ─── PRODUCT TILE ────────────────────────────────────────────────────────────

class ProductListTile extends StatelessWidget {
  final Product product;
  final Widget? trailing;
  final VoidCallback? onTap;

  const ProductListTile({super.key, required this.product, this.trailing, this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(color: cs.primaryContainer, borderRadius: BorderRadius.circular(10)),
        alignment: Alignment.center,
        child: Text(product.name[0], style: TextStyle(color: cs.primary, fontWeight: FontWeight.w800, fontSize: 18)),
      ),
      title: Row(children: [
        Expanded(child: Text(product.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis)),
        if (product.isLowStock) ...[const SizedBox(width: 6), const LowStockBadge()],
      ]),
      subtitle: Text('${fmtRupee(product.price)} / ${product.unit}  ·  Stock: ${product.stock}', style: TextStyle(fontSize: 12, color: cs.onSurface.withOpacity(0.6))),
      trailing: trailing,
    );
  }
}

// ─── SHIMMER LOADER ──────────────────────────────────────────────────────────

class ShimmerBox extends StatelessWidget {
  final double width;
  final double height;
  final double radius;

  const ShimmerBox({super.key, required this.width, required this.height, this.radius = 8});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
