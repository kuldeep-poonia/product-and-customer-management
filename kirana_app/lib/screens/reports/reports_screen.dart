import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme.dart';
import '../../core/models.dart';
import '../../core/providers.dart';
import '../../core/widgets.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bills = ref.watch(billsProvider);
    final billsNotifier = ref.read(billsProvider.notifier);
    final customers = ref.watch(customersProvider);
    final cs = Theme.of(context).colorScheme;

    final todaySales = billsNotifier.todaySales;
    final todayBills = billsNotifier.todayBills;

    // Today profit (simplified: selling - cost)
    final todayProfit = todayBills.fold<double>(0, (s, b) {
      return s + b.items.fold<double>(0, (si, i) => si + (i.unitPrice - i.product.costPrice) * i.qty) - b.discount;
    });
    final profitMargin = todaySales > 0 ? (todayProfit / todaySales * 100) : 0;

    // Weekly data (last 7 days)
    final now = DateTime.now();
    final weekData = List.generate(7, (i) {
      final day = now.subtract(Duration(days: 6 - i));
      final dayBills = bills.where((b) => b.createdAt.day == day.day && b.createdAt.month == day.month).toList();
      return dayBills.fold<double>(0, (s, b) => s + b.total);
    });

    // Best selling items
    final Map<String, double> itemSales = {};
    final Map<String, String> itemNames = {};
    for (final b in bills) {
      for (final i in b.items) {
        itemSales[i.product.id] = (itemSales[i.product.id] ?? 0) + i.total;
        itemNames[i.product.id] = i.product.name;
      }
    }
    final topItems = itemSales.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    // Credit risk (overdue)
    final riskCustomers = customers.where((c) => c.isOverdue && c.totalDue > 0).toList()..sort((a, b) => b.totalDue.compareTo(a.totalDue));

    return Scaffold(
      appBar: AppBar(title: const Text('Reports & Analytics')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // ── Today Stats ───────────────────────────────────────────────
          Row(children: [
            Expanded(child: StatCard(label: "Today's Profit", value: fmtRupee(todayProfit), icon: Icons.trending_up, iconColor: AppColors.green600, bgColor: AppColors.green50, subtitle: '${profitMargin.toStringAsFixed(1)}% margin')),
            const SizedBox(width: 12),
            Expanded(child: StatCard(label: "Today's Sales", value: fmtRupee(todaySales), icon: Icons.receipt_long_outlined, iconColor: AppColors.blue600, bgColor: AppColors.blue50, subtitle: '${todayBills.length} bills')),
          ]),
          const SizedBox(height: 20),

          // ── Weekly Sales Chart ────────────────────────────────────────
          const SectionHeader(title: '📊  Weekly Sales (Last 7 Days)', actionLabel: null, onAction: null),
          const SizedBox(height: 12),
          Container(
            height: 180,
            padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
            decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(16)),
            child: BarChart(
              BarChartData(
                barGroups: List.generate(7, (i) {
                  final day = now.subtract(Duration(days: 6 - i));
                  return BarChartGroupData(x: i, barRods: [
                    BarChartRodData(
                      toY: weekData[i],
                      color: i == 6 ? AppColors.green600 : AppColors.green600.withOpacity(0.5),
                      width: 22,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                    ),
                  ]);
                }),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (v, meta) {
                      final day = now.subtract(Duration(days: 6 - v.toInt()));
                      final labels = ['Mo','Tu','We','Th','Fr','Sa','Su'];
                      return Padding(padding: const EdgeInsets.only(top: 4), child: Text(labels[day.weekday - 1], style: TextStyle(fontSize: 11, color: cs.outline)));
                    },
                  )),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  // If all days have zero sales, reduce returns 0 and fl_chart
                  // throws an assertion error on horizontalInterval: 0.
                  // Clamp to at least 100 so the grid always renders.
                  horizontalInterval: (weekData.reduce((a, b) => a > b ? a : b) / 4).clamp(100, double.infinity),
                  getDrawingHorizontalLine: (v) => FlLine(color: cs.outlineVariant.withOpacity(0.5), strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (g, gi, r, ri) => BarTooltipItem(fmtRupee(r.toY), const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // ── Best Selling ──────────────────────────────────────────────
          const SectionHeader(title: '🏆  Best Selling Items', actionLabel: null, onAction: null),
          const SizedBox(height: 10),
          ...topItems.take(5).toList().asMap().entries.map((entry) {
            final i = entry.key;
            final e = entry.value;
            final maxSale = topItems.first.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(12)),
                child: Row(children: [
                  Container(
                    width: 28, height: 28,
                    decoration: BoxDecoration(color: i == 0 ? const Color(0xFFFFD700) : i == 1 ? const Color(0xFFC0C0C0) : i == 2 ? const Color(0xFFCD7F32) : cs.surfaceContainerHighest, shape: BoxShape.circle),
                    alignment: Alignment.center,
                    child: Text('${i + 1}', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: i < 3 ? Colors.black : cs.outline)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(itemNames[e.key] ?? e.key, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    ClipRRect(borderRadius: BorderRadius.circular(3), child: LinearProgressIndicator(value: maxSale > 0 ? e.value / maxSale : 0, minHeight: 5, backgroundColor: cs.outlineVariant, valueColor: AlwaysStoppedAnimation(AppColors.green600.withOpacity(0.7)))),
                  ])),
                  const SizedBox(width: 10),
                  Text(fmtRupee(e.value), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                ]),
              ),
            );
          }),
          const SizedBox(height: 20),

          // ── Payment Split ─────────────────────────────────────────────
          const SectionHeader(title: '💳  Payment Split (Today)', actionLabel: null, onAction: null),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(14)),
            child: Row(children: [
              Expanded(child: _PaySplit(label: 'Cash', value: billsNotifier.todayCash, color: AppColors.green600, icon: Icons.payments_outlined)),
              Container(width: 1, height: 50, color: cs.outlineVariant),
              Expanded(child: _PaySplit(label: 'UPI', value: billsNotifier.todayUpi, color: AppColors.blue600, icon: Icons.phonelink_ring_outlined)),
              Container(width: 1, height: 50, color: cs.outlineVariant),
              Expanded(child: _PaySplit(label: 'Udhaar', value: todayBills.where((b) => b.paymentMode == PaymentMode.udhaar).fold(0, (s, b) => s + b.total), color: AppColors.red600, icon: Icons.book_outlined)),
            ]),
          ),
          const SizedBox(height: 20),

          // ── Credit Risk ───────────────────────────────────────────────
          if (riskCustomers.isNotEmpty) ...[
            const SectionHeader(title: '⚠️  Credit Risk Customers', actionLabel: null, onAction: null),
            const SizedBox(height: 10),
            ...riskCustomers.take(5).map((c) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.red400.withOpacity(0.25))),
                child: Row(children: [
                  CircleAvatar(radius: 18, backgroundColor: AppColors.red50, child: Text(c.name[0], style: const TextStyle(color: AppColors.red600, fontWeight: FontWeight.w800))),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(c.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    Text('${DateTime.now().difference(c.lastActivity).inDays} days overdue', style: const TextStyle(fontSize: 12, color: AppColors.red600)),
                  ])),
                  Text(fmtRupee(c.totalDue), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.red600)),
                ]),
              ),
            )),
          ],
        ]),
      ),
    );
  }
}

class _PaySplit extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final IconData icon;

  const _PaySplit({required this.label, required this.value, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Icon(icon, color: color, size: 22),
      const SizedBox(height: 6),
      Text(fmtRupee(value), style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: color)),
      const SizedBox(height: 2),
      Text(label, style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.outline)),
    ]);
  }
}
