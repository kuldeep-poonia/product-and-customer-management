import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../core/app_constants.dart';
import 'package:shopiq/app/app_localizations.dart';
import '../../core/models.dart';
import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../auth/auth_screen.dart';
import '../../core/providers/subscription_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final billsNotifier = ref.read(billsProvider.notifier);
    final products = ref.watch(productsProvider);
    final customers = ref.watch(customersProvider);
    final custNotifier = ref.read(customersProvider.notifier);
    final suppliers = ref.watch(suppliersProvider);
    final orders = ref.watch(ordersProvider);
    final bills = ref.watch(billsProvider);
    final isDark = ref.watch(darkModeProvider);
    final cs = Theme.of(context).colorScheme;
    final l = context.l10n;

    final todaySales = billsNotifier.todaySales;
    final todayCash = billsNotifier.todayCash;
    final todayUpi = billsNotifier.todayUpi;
    final totalUdhaar = custNotifier.totalPendingUdhaar;
    final lowStock = products.where((p) => p.isLowStock).toList();
    final pendingOrders = orders.where((o) => o.status == OrderStatus.pending).length;
    final supplierDue = suppliers.fold<double>(0, (s, x) => s + x.amountDue);

    final Map<String, int> freq = {};
    for (final b in bills) {
      for (final i in b.items) {
        freq[i.product.id] = (freq[i.product.id] ?? 0) + i.qty;
      }
    }
    final topItems = [...products]..sort((a, b) => (freq[b.id] ?? 0).compareTo(freq[a.id] ?? 0));
    final top5 = topItems.take(5).toList();

    // Use auth shop name if available
    final shopDisplayName = ref.watch(authProvider).shopName ?? AppConstants.defaultShopName;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(shopDisplayName, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
              Text(AppConstants.defaultShopLocation, style: TextStyle(fontSize: 11, color: cs.outline, fontWeight: FontWeight.w400)),
            ]),
            actions: [
              IconButton(icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode), onPressed: () => ref.read(darkModeProvider.notifier).state = !isDark),
              IconButton(icon: const Icon(Icons.notifications_outlined), onPressed: () {}),
              const SizedBox(width: 4),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
            sliver: SliverList(delegate: SliverChildListDelegate([
              const _StatusBanner(),
              _TodaySalesCard(todaySales: todaySales, todayCash: todayCash, todayUpi: todayUpi, label: l.todaySale),
              const SizedBox(height: 16),

              Row(children: [
                Expanded(child: StatCard(label: l.pendingUdhaar, value: fmtRupee(totalUdhaar), icon: Icons.account_balance_wallet_outlined, iconColor: AppColors.red600, bgColor: AppColors.red50, onTap: () => context.go('/khata'), subtitle: '${customers.where((c) => c.totalDue > 0).length} ${l.customers}')),
                const SizedBox(width: 12),
                Expanded(child: StatCard(label: l.lowStock, value: '${lowStock.length} items', icon: Icons.warning_amber_outlined, iconColor: AppColors.amber600, bgColor: AppColors.amber50, onTap: () => context.go('/inventory'), subtitle: lowStock.isNotEmpty ? lowStock.first.name : 'All good ✓')),
              ]),
              const SizedBox(height: 12),

              Row(children: [
                Expanded(child: StatCard(label: l.supplierDue, value: fmtRupee(supplierDue), icon: Icons.local_shipping_outlined, iconColor: AppColors.blue600, bgColor: AppColors.blue50, subtitle: '${suppliers.where((s) => s.amountDue > 0).length} suppliers')),
                const SizedBox(width: 12),
                Expanded(child: StatCard(label: l.newOrders, value: '$pendingOrders pending', icon: Icons.delivery_dining_outlined, iconColor: AppColors.green600, bgColor: AppColors.green50, onTap: () => context.go('/orders'))),
              ]),
              const SizedBox(height: 20),

              if (lowStock.isNotEmpty) ...[
                SectionHeader(title: l.lowStockAlerts, actionLabel: l.addStock, onAction: () => context.go('/inventory')),
                const SizedBox(height: 10),
                ...lowStock.take(3).map((p) => Padding(padding: const EdgeInsets.only(bottom: 8), child: _LowStockTile(product: p))),
                const SizedBox(height: 16),
              ],

              if (customers.any((c) => c.isOverdue)) ...[
                SectionHeader(title: l.overdueKhata, actionLabel: l.seeAll, onAction: () => context.go('/khata')),
                const SizedBox(height: 10),
                ...customers.where((c) => c.isOverdue).take(3).map((c) => Padding(padding: const EdgeInsets.only(bottom: 8), child: _OverdueTile(customer: c))),
                const SizedBox(height: 16),
              ],

              SectionHeader(title: l.topSelling, actionLabel: l.reports, onAction: () => context.go('/reports')),
              const SizedBox(height: 10),
              SizedBox(
                height: 100,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.only(bottom: 4),
                  itemCount: top5.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (_, i) => _TopItemCard(product: top5[i], rank: i + 1, sold: freq[top5[i].id] ?? 0),
                ),
              ),
              const SizedBox(height: 20),

              // Suppliers
              SectionHeader(title: '🚚  Suppliers', actionLabel: 'Manage', onAction: () => context.push('/suppliers')),
              const SizedBox(height: 10),
              ...suppliers.where((s) => s.amountDue > 0).map((s) => Padding(padding: const EdgeInsets.only(bottom: 8), child: _SupplierTile(supplier: s))),
              const SizedBox(height: 8),
            ])),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'quick-bill',
        onPressed: () => context.push('/billing'),
        backgroundColor: AppColors.green600,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.receipt_long),
        label: const Text('Quick Bill', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }
}

class _StatusBanner extends ConsumerWidget {
  const _StatusBanner();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sub = ref.watch(subscriptionProvider);
    if (sub.isLoading) return const SizedBox.shrink();
    if (sub.hasAccess && sub.trialDaysLeft > 2) return const SizedBox.shrink();

    Color bgColor = AppColors.amber50;
    Color textColor = AppColors.amber600;
    IconData icon = Icons.warning_amber_rounded;
    String title = '';
    String action = 'Upgrade';

    if (sub.isPending) {
       bgColor = AppColors.blue50;
       textColor = AppColors.blue600;
       icon = Icons.history_toggle_off_rounded;
       title = 'Verification in progress...';
       action = 'Details';
    } else if (sub.isExpired) {
       bgColor = AppColors.red50;
       textColor = AppColors.red600;
       icon = Icons.lock_outline;
       title = 'Trial expired. Upgrade to save bills.';
       action = 'Upgrade';
    } else if (sub.trialDaysLeft <= 2) {
       title = 'Trial ending in ${sub.trialDaysLeft} days. Upgrade soon!';
    } else {
       return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticFeedback.lightImpact();
          context.push('/subscription');
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: textColor.withOpacity(0.2)),
          ),
          child: Row(children: [
            Icon(icon, color: textColor, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(title, style: TextStyle(color: textColor, fontWeight: FontWeight.w600, fontSize: 13))),
            const SizedBox(width: 8),
            Text(action, style: TextStyle(color: textColor, fontWeight: FontWeight.w800, fontSize: 13, decoration: TextDecoration.underline)),
          ]),
        ),
      ),
    );
  }
}

class _TodaySalesCard extends StatelessWidget {
  final double todaySales, todayCash, todayUpi;
  final String label;
  const _TodaySalesCard({required this.todaySales, required this.todayCash, required this.todayUpi, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppColors.green600, AppColors.green700], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: AppColors.green600.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
            child: Text(fmtDay(DateTime.now()), style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
          ),
        ]),
        const SizedBox(height: 8),
        Text(fmtRupee(todaySales), style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900)),
        const SizedBox(height: 16),
        Row(children: [
          _MiniStat(label: 'Cash', value: fmtRupee(todayCash), icon: Icons.payments_outlined),
          const SizedBox(width: 24),
          _MiniStat(label: 'UPI', value: fmtRupee(todayUpi), icon: Icons.phonelink_ring_outlined),
        ]),
      ]),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label, value;
  final IconData icon;
  const _MiniStat({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext ctx) => Row(children: [
    Icon(icon, color: Colors.white70, size: 16),
    const SizedBox(width: 6),
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
      Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
    ]),
  ]);
}

class _LowStockTile extends StatelessWidget {
  final Product product;
  const _LowStockTile({required this.product});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark ? AppColors.red600.withOpacity(0.1) : AppColors.red50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.red400.withOpacity(0.2)),
      ),
      child: Row(children: [
        const Icon(Icons.warning_amber_rounded, color: AppColors.red600, size: 20),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(product.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
          Text('Only ${product.stock} ${product.unit} left', style: const TextStyle(fontSize: 12, color: AppColors.red600)),
        ])),
        Text(fmtRupee(product.price), style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Theme.of(context).colorScheme.onSurface)),
      ]),
    );
  }
}

class _OverdueTile extends StatelessWidget {
  final Customer customer;
  const _OverdueTile({required this.customer});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        CircleAvatar(radius: 18, backgroundColor: AppColors.red50, child: Text(customer.name[0], style: const TextStyle(color: AppColors.red600, fontWeight: FontWeight.w800))),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(customer.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          Text('${DateTime.now().difference(customer.lastActivity).inDays}d overdue', style: const TextStyle(fontSize: 12, color: AppColors.red600)),
        ])),
        Text(fmtRupee(customer.totalDue), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.red600)),
      ]),
    );
  }
}

class _TopItemCard extends StatelessWidget {
  final Product product;
  final int rank, sold;
  const _TopItemCard({required this.product, required this.rank, required this.sold});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: 120,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(14)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        Row(children: [
          Flexible(child: Text('#$rank', style: TextStyle(fontSize: 10, color: cs.primary, fontWeight: FontWeight.w800))),
          const Spacer(),
          const Icon(Icons.trending_up, size: 14, color: AppColors.green600),
        ]),
        const SizedBox(height: 4),
        Text(product.name, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700), maxLines: 2, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 2),
        Text('$sold sold', style: TextStyle(fontSize: 10, color: cs.outline)),
      ]),
    );
  }
}

class _SupplierTile extends StatelessWidget {
  final Supplier supplier;
  const _SupplierTile({required this.supplier});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        Container(width: 40, height: 40, decoration: BoxDecoration(color: cs.secondaryContainer, borderRadius: BorderRadius.circular(10)), alignment: Alignment.center, child: Icon(Icons.local_shipping_outlined, size: 20, color: cs.secondary)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(supplier.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          Text('Last: ${fmtDay(DateTime.now())}', style: TextStyle(fontSize: 11, color: cs.outline)),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(fmtRupee(supplier.amountDue), style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: supplier.amountDue > 0 ? AppColors.red600 : AppColors.green600)),
          Text('due', style: TextStyle(fontSize: 11, color: cs.outline)),
        ]),
      ]),
    );
  }
}