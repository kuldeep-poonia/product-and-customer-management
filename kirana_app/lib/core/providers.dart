import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';

// ─── LANGUAGE ────────────────────────────────────────────────────────────────
// Centralised here so main.dart can watch it for locale switching.
// On first launch auto-detects device locale (hi → Hindi, else English).

class LanguageNotifier extends StateNotifier<String> {
  LanguageNotifier() : super('en') {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('language');
    if (saved != null) {
      state = saved;
      return;
    }
    // Auto-detect system locale — no restart needed
    try {
      final sysLang =
          WidgetsBinding.instance.platformDispatcher.locale.languageCode;
      state = (sysLang == 'hi') ? 'hi' : 'en';
    } catch (_) {
      state = 'en';
    }
  }

  Future<void> setLanguage(String code) async {
    state = code;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', code);
  }
}

final languageProvider = StateNotifierProvider<LanguageNotifier, String>(
  (ref) => LanguageNotifier(),
);

// ─── PRODUCTS ───────────────────────────────────────────────────────────────

class ProductsNotifier extends StateNotifier<List<Product>> {
  ProductsNotifier() : super(mockProducts);

  void updateStock(String id, int delta) {
    state = [
      for (final p in state)
        if (p.id == id) p.copyWith(stock: (p.stock + delta).clamp(0, 9999)) else p
    ];
  }

  void addStock(String id, int qty) => updateStock(id, qty);

  List<Product> get lowStockItems => state.where((p) => p.isLowStock).toList();

  List<Product> search(String query) {
    if (query.isEmpty) return state;
    final q = query.toLowerCase();
    return state.where((p) =>
        p.name.toLowerCase().contains(q) ||
        p.nameHi.contains(query) ||
        p.category.toLowerCase().contains(q)).toList();
  }

  // Returns null if all items can be fulfilled, or a human-readable
  // error string naming the first item that would go negative.
  String? validateCartStock(List<BillItem> cartItems) {
    for (final item in cartItems) {
      final product = state.firstWhere(
        (p) => p.id == item.product.id,
        orElse: () => item.product,
      );
      if (item.qty > product.stock) {
        return '${product.name}: only ${product.stock} ${product.unit} left in stock.';
      }
    }
    return null;
  }
}

final productsProvider = StateNotifierProvider<ProductsNotifier, List<Product>>(
  (ref) => ProductsNotifier(),
);

// ─── BILLING ────────────────────────────────────────────────────────────────

class BillingNotifier extends StateNotifier<List<BillItem>> {
  BillingNotifier() : super([]);

  void addItem(Product product) {
    final existing = state.indexWhere((i) => i.product.id == product.id);
    if (existing >= 0) {
      state = [
        for (int i = 0; i < state.length; i++)
          if (i == existing)
            BillItem(product: state[i].product, qty: state[i].qty + 1, overridePrice: state[i].overridePrice)
          else
            state[i]
      ];
    } else {
      state = [...state, BillItem(product: product)];
    }
  }

  void updateQty(String productId, int qty) {
    if (qty <= 0) {
      removeItem(productId);
      return;
    }
    state = [
      for (final item in state)
        if (item.product.id == productId)
          BillItem(product: item.product, qty: qty, overridePrice: item.overridePrice)
        else
          item
    ];
  }

  void removeItem(String productId) {
    state = state.where((i) => i.product.id != productId).toList();
  }

  void clear() => state = [];

  double get subtotal => state.fold(0, (s, i) => s + i.total);
}

final billingProvider = StateNotifierProvider<BillingNotifier, List<BillItem>>(
  (ref) => BillingNotifier(),
);

// ─── SAVED BILLS ────────────────────────────────────────────────────────────

class BillsNotifier extends StateNotifier<List<Bill>> {
  BillsNotifier() : super(_seedBills());

  void addBill(Bill bill) => state = [bill, ...state];

  List<Bill> get todayBills {
    final now = DateTime.now();
    return state.where((b) =>
        b.createdAt.day == now.day &&
        b.createdAt.month == now.month &&
        b.createdAt.year == now.year).toList();
  }

  double get todaySales => todayBills.fold(0, (s, b) => s + b.total);

  double get todayCash => todayBills
      .where((b) => b.paymentMode == PaymentMode.cash)
      .fold(0, (s, b) => s + b.total);

  double get todayUpi => todayBills
      .where((b) => b.paymentMode == PaymentMode.upi)
      .fold(0, (s, b) => s + b.total);
}

List<Bill> _seedBills() {
  final now = DateTime.now();
  return [
    Bill(id: 'b1', customerName: 'Ramesh', items: [BillItem(product: mockProducts[0], qty: 1), BillItem(product: mockProducts[2], qty: 2)], paymentMode: PaymentMode.cash, createdAt: now.subtract(const Duration(hours: 1)), isPaid: true),
    Bill(id: 'b2', customerName: 'Walk-in', items: [BillItem(product: mockProducts[8], qty: 3), BillItem(product: mockProducts[7], qty: 2)], paymentMode: PaymentMode.upi, createdAt: now.subtract(const Duration(hours: 2)), isPaid: true),
    Bill(id: 'b3', customerName: 'Sunita', items: [BillItem(product: mockProducts[5], qty: 2)], paymentMode: PaymentMode.udhaar, createdAt: now.subtract(const Duration(hours: 3)), isPaid: false),
    Bill(id: 'b4', items: [BillItem(product: mockProducts[3], qty: 1), BillItem(product: mockProducts[9], qty: 1)], paymentMode: PaymentMode.cash, createdAt: now.subtract(const Duration(days: 1)), isPaid: true),
    Bill(id: 'b5', customerName: 'Walk-in', items: [BillItem(product: mockProducts[6], qty: 1)], paymentMode: PaymentMode.upi, createdAt: now.subtract(const Duration(days: 1)), isPaid: true),
  ];
}

final billsProvider = StateNotifierProvider<BillsNotifier, List<Bill>>(
  (ref) => BillsNotifier(),
);

// ─── CUSTOMERS / KHATA ──────────────────────────────────────────────────────

class CustomersNotifier extends StateNotifier<List<Customer>> {
  CustomersNotifier() : super(mockCustomers);

  void addPayment(String customerId, double amount, String note) {
    state = [
      for (final c in state)
        if (c.id == customerId)
          Customer(
            id: c.id,
            name: c.name,
            phone: c.phone,
            address: c.address,
            khata: [
              ...c.khata,
              KhataEntry(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                type: 'credit',
                amount: amount,
                note: note,
                date: DateTime.now(),
              )
            ],
            lastActivity: DateTime.now(),
          )
        else
          c
    ];
  }

  void addDebit(String customerId, double amount, String note) {
    state = [
      for (final c in state)
        if (c.id == customerId)
          Customer(
            id: c.id,
            name: c.name,
            phone: c.phone,
            address: c.address,
            khata: [
              ...c.khata,
              KhataEntry(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                type: 'debit',
                amount: amount,
                note: note,
                date: DateTime.now(),
              )
            ],
            lastActivity: DateTime.now(),
          )
        else
          c
    ];
  }

  double get totalPendingUdhaar =>
      state.fold(0, (s, c) => s + (c.totalDue > 0 ? c.totalDue : 0));
}

final customersProvider = StateNotifierProvider<CustomersNotifier, List<Customer>>(
  (ref) => CustomersNotifier(),
);

// ─── ORDERS ─────────────────────────────────────────────────────────────────

class OrdersNotifier extends StateNotifier<List<Order>> {
  OrdersNotifier() : super(mockOrders);

  void updateStatus(String id, OrderStatus status) {
    state = [
      for (final o in state)
        if (o.id == id)
          Order(
            id: o.id,
            customerName: o.customerName,
            customerPhone: o.customerPhone,
            address: o.address,
            items: o.items,
            status: status,
            source: o.source,
            isCOD: o.isCOD,
            riderNote: o.riderNote,
            createdAt: o.createdAt,
          )
        else
          o
    ];
  }

  List<Order> get pending => state.where((o) => o.status == OrderStatus.pending).toList();
}

final ordersProvider = StateNotifierProvider<OrdersNotifier, List<Order>>(
  (ref) => OrdersNotifier(),
);

// ─── SUPPLIERS ──────────────────────────────────────────────────────────────

class SuppliersNotifier extends StateNotifier<List<Supplier>> {
  SuppliersNotifier() : super(mockSuppliers);

  void addSupplier(Supplier supplier) {
    state = [supplier, ...state];
  }

  void updateSupplier(Supplier updated) {
    state = [
      for (final s in state) if (s.id == updated.id) updated else s
    ];
  }

  void deleteSupplier(String id) {
    state = state.where((s) => s.id != id).toList();
  }

  void addTransaction(String supplierId, SupplierTransaction tx) {
    state = [
      for (final s in state)
        if (s.id == supplierId)
          s.copyWith(
            transactions: [...s.transactions, tx],
            amountDue: tx.type == 'supply'
                ? s.amountDue + tx.amount
                : (s.amountDue - tx.amount).clamp(0, double.infinity),
            lastSupplyDate:
                tx.type == 'supply' ? tx.date : s.lastSupplyDate,
          )
        else
          s
    ];
  }

  void recordPayment(String supplierId, double amount, String note) {
    addTransaction(
      supplierId,
      SupplierTransaction(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: 'payment',
        amount: amount,
        note: note,
        date: DateTime.now(),
      ),
    );
  }

  List<Supplier> get overdueSuppliers => state
      .where((s) => s.amountDue > 0 && s.isOverdue)
      .toList();

  List<Supplier> search(String query) {
    if (query.isEmpty) return state;
    final q = query.toLowerCase();
    return state
        .where((s) =>
            s.name.toLowerCase().contains(q) ||
            (s.companyName?.toLowerCase().contains(q) ?? false) ||
            s.phone.contains(q))
        .toList();
  }
}

final suppliersProvider =
    StateNotifierProvider<SuppliersNotifier, List<Supplier>>(
  (ref) => SuppliersNotifier(),
);

// ─── THEME ──────────────────────────────────────────────────────────────────

final darkModeProvider = StateProvider<bool>((ref) => false);

// paymentMode is scoped to billing flow only, reset on bill save or screen dispose.
final paymentModeProvider = StateProvider<PaymentMode>((ref) => PaymentMode.cash);