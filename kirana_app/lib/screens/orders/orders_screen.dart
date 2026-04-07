import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../app/theme.dart';
import '../../core/app_constants.dart';
import '../../core/models.dart';
import '../../core/providers.dart';
import '../../core/widgets.dart';

class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() { _tabCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final orders = ref.watch(ordersProvider);
    final pending = orders.where((o) => o.status == OrderStatus.pending).toList();
    final packed = orders.where((o) => o.status == OrderStatus.packed).toList();
    final outDelivery = orders.where((o) => o.status == OrderStatus.outForDelivery).toList();
    final delivered = orders.where((o) => o.status == OrderStatus.delivered).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Orders & Delivery'),
        bottom: TabBar(
          controller: _tabCtrl,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: [
            Tab(text: pending.isNotEmpty ? 'Pending (${pending.length})' : 'Pending'),
            Tab(text: packed.isNotEmpty ? 'Packed (${packed.length})' : 'Packed'),
            const Tab(text: 'On Way'),
            const Tab(text: 'Delivered'),
          ],
          labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _OrderList(orders: pending, emptyLabel: 'No pending orders'),
          _OrderList(orders: packed, emptyLabel: 'No packed orders'),
          _OrderList(orders: outDelivery, emptyLabel: 'No deliveries en route'),
          _OrderList(orders: delivered, emptyLabel: 'No deliveries today'),
        ],
      ),
    );
  }
}

class _OrderList extends ConsumerWidget {
  final List<Order> orders;
  final String emptyLabel;
  const _OrderList({required this.orders, required this.emptyLabel});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (orders.isEmpty) {
      return EmptyState(icon: Icons.delivery_dining_outlined, title: emptyLabel, subtitle: 'WhatsApp orders will appear here');
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _OrderCard(order: orders[i], ref: ref),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Order order;
  final WidgetRef ref;
  const _OrderCard({required this.order, required this.ref});

  static const _statusColors = {
    OrderStatus.pending: AppColors.amber600,
    OrderStatus.packed: AppColors.blue600,
    OrderStatus.outForDelivery: AppColors.green600,
    OrderStatus.delivered: Color(0xFF9E9E9E),
    OrderStatus.cancelled: AppColors.red600,
  };

  static const _statusLabels = {
    OrderStatus.pending: 'Pending',
    OrderStatus.packed: 'Packed',
    OrderStatus.outForDelivery: 'On the Way',
    OrderStatus.delivered: 'Delivered',
    OrderStatus.cancelled: 'Cancelled',
  };

  static const _nextStatus = {
    OrderStatus.pending: OrderStatus.packed,
    OrderStatus.packed: OrderStatus.outForDelivery,
    OrderStatus.outForDelivery: OrderStatus.delivered,
  };

  static const _nextLabel = {
    OrderStatus.pending: 'Mark Packed',
    OrderStatus.packed: 'Out for Delivery',
    OrderStatus.outForDelivery: 'Mark Delivered',
  };

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = _statusColors[order.status] ?? cs.outline;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header
        Row(children: [
          Flexible(
            child: Row(children: [
              Flexible(
                child: Text(order.customerName,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                    overflow: TextOverflow.ellipsis),
              ),
              const SizedBox(width: 6),
              if (order.isCOD) const AlertChip(label: 'COD', color: AppColors.amber600, icon: Icons.payments_outlined),
              if (order.isCOD && order.source == 'whatsapp') const SizedBox(width: 4),
              if (order.source == 'whatsapp') const AlertChip(label: 'WA', color: AppColors.waGreen, icon: Icons.chat),
            ]),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Text(_statusLabels[order.status] ?? '', style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
          ),
        ]),
        const SizedBox(height: 6),
        Text(order.customerPhone, style: TextStyle(fontSize: 12, color: cs.outline)),
        if (order.address != null) ...[
          const SizedBox(height: 2),
          Text('📍 ${order.address}', style: TextStyle(fontSize: 12, color: cs.outline), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
        const SizedBox(height: 10),

        // Items
        ...order.items.map((item) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(children: [
            Expanded(child: Text('• ${item.product.name} × ${item.qty}', style: const TextStyle(fontSize: 13))),
            Text(fmtRupee(item.total), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          ]),
        )),
        const Divider(height: 20),

        // Footer
        Row(children: [
          Text(fmtRupee(order.total), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.chat, color: AppColors.waGreen, size: 22),
            onPressed: () => _whatsapp(order),
            tooltip: 'WhatsApp',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 12),
          IconButton(
            icon: Icon(Icons.phone, color: cs.primary, size: 22),
            onPressed: () => _call(order.customerPhone),
            tooltip: 'Call',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          if (_nextStatus[order.status] != null) ...[
            const SizedBox(width: 12),
            FilledButton(
              onPressed: () => ref.read(ordersProvider.notifier).updateStatus(order.id, _nextStatus[order.status]!),
              style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10)),
              child: Text(_nextLabel[order.status] ?? '', style: const TextStyle(fontSize: 12)),
            ),
          ],
        ]),
      ]),
    );
  }

  Future<void> _whatsapp(Order o) async {
    final text = Uri.encodeComponent('Hello ${o.customerName} ji\nYour order of ${fmtRupee(o.total)} is ${_statusLabels[o.status]?.toLowerCase()}.\n\n${o.items.map((i) => '${i.product.name} x${i.qty}').join('\n')}\n\nThank you! - ${AppConstants.defaultShopName} (${AppConstants.appName})');
    final url = Uri.parse('https://wa.me/91${o.customerPhone}?text=$text');
    if (await canLaunchUrl(url)) await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  Future<void> _call(String phone) async {
    final url = Uri.parse('tel:$phone');
    if (await canLaunchUrl(url)) await launchUrl(url);
  }
}