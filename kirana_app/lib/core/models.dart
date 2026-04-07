// Models for ShopIQ. No framework imports needed here — pure Dart only.

// ─── PRODUCT / INVENTORY ───────────────────────────────────────────────────

class Product {
  final String id;
  final String name;
  final String nameHi; // Hindi name
  final String category;
  final double price; // selling price
  final double costPrice;
  final int stock; // current stock in units
  final int lowStockThreshold;
  final String unit; // kg, litre, pcs, packet
  final String? supplier;
  final DateTime? expiryDate;

  const Product({
    required this.id,
    required this.name,
    required this.nameHi,
    required this.category,
    required this.price,
    required this.costPrice,
    required this.stock,
    required this.lowStockThreshold,
    required this.unit,
    this.supplier,
    this.expiryDate,
  });

  bool get isLowStock => stock <= lowStockThreshold;
  double get margin => ((price - costPrice) / costPrice) * 100;

  Product copyWith({int? stock, double? price}) => Product(
        id: id,
        name: name,
        nameHi: nameHi,
        category: category,
        price: price ?? this.price,
        costPrice: costPrice,
        stock: stock ?? this.stock,
        lowStockThreshold: lowStockThreshold,
        unit: unit,
        supplier: supplier,
        expiryDate: expiryDate,
      );
}

// ─── BILL ITEM ──────────────────────────────────────────────────────────────

class BillItem {
  final Product product;
  int qty;
  double? overridePrice;

  BillItem({required this.product, this.qty = 1, this.overridePrice});

  double get unitPrice => overridePrice ?? product.price;
  double get total => unitPrice * qty;
}

// ─── BILL / INVOICE ─────────────────────────────────────────────────────────

enum PaymentMode { cash, upi, udhaar, mixed }

class Bill {
  final String id;
  final String? customerId;
  final String? customerName;
  final String? customerPhone;
  final List<BillItem> items;
  final PaymentMode paymentMode;
  final double discount;
  final DateTime createdAt;
  final bool isPaid;

  const Bill({
    required this.id,
    this.customerId,
    this.customerName,
    this.customerPhone,
    required this.items,
    required this.paymentMode,
    this.discount = 0,
    required this.createdAt,
    this.isPaid = true,
  });

  double get subtotal => items.fold(0, (s, i) => s + i.total);
  double get total => subtotal - discount;
  int get itemCount => items.fold(0, (s, i) => s + i.qty);
}

// ─── CUSTOMER / KHATA ───────────────────────────────────────────────────────

class KhataEntry {
  final String id;
  final String type; // 'debit' | 'credit'
  final double amount;
  final String note;
  final DateTime date;

  const KhataEntry({
    required this.id,
    required this.type,
    required this.amount,
    required this.note,
    required this.date,
  });
}

class Customer {
  final String id;
  final String name;
  final String phone;
  final String? address;
  final List<KhataEntry> khata;
  final DateTime lastActivity;

  const Customer({
    required this.id,
    required this.name,
    required this.phone,
    this.address,
    required this.khata,
    required this.lastActivity,
  });

  double get totalDue => khata.fold(0, (s, e) {
        return e.type == 'debit' ? s + e.amount : s - e.amount;
      });

  bool get isOverdue => totalDue > 0 &&
      DateTime.now().difference(lastActivity).inDays > 7;
}

// ─── ORDER ──────────────────────────────────────────────────────────────────

enum OrderStatus { pending, packed, outForDelivery, delivered, cancelled }

class Order {
  final String id;
  final String customerName;
  final String customerPhone;
  final String? address;
  final List<BillItem> items;
  final OrderStatus status;
  final String source; // 'whatsapp' | 'walkin' | 'phone'
  final bool isCOD;
  final String? riderNote;
  final DateTime createdAt;

  const Order({
    required this.id,
    required this.customerName,
    required this.customerPhone,
    this.address,
    required this.items,
    required this.status,
    required this.source,
    this.isCOD = false,
    this.riderNote,
    required this.createdAt,
  });

  double get total => items.fold(0, (s, i) => s + i.total);
}

// ─── SUPPLIER ───────────────────────────────────────────────────────────────

class SupplierTransaction {
  final String id;
  final String type; // 'payment' | 'supply'
  final double amount;
  final String note;
  final DateTime date;

  const SupplierTransaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.note,
    required this.date,
  });
}

class Supplier {
  final String id;
  final String name;
  final String phone;
  final String? companyName;
  final double amountDue;
  final DateTime? lastSupplyDate;
  final String? productNotes;
  final List<SupplierTransaction> transactions;

  const Supplier({
    required this.id,
    required this.name,
    required this.phone,
    this.companyName,
    required this.amountDue,
    this.lastSupplyDate,
    this.productNotes,
    this.transactions = const [],
  });

  bool get isOverdue =>
      amountDue > 0 &&
      lastSupplyDate != null &&
      DateTime.now().difference(lastSupplyDate!).inDays > 30;

  Supplier copyWith({
    String? name,
    String? phone,
    String? companyName,
    double? amountDue,
    DateTime? lastSupplyDate,
    String? productNotes,
    List<SupplierTransaction>? transactions,
  }) =>
      Supplier(
        id: id,
        name: name ?? this.name,
        phone: phone ?? this.phone,
        companyName: companyName ?? this.companyName,
        amountDue: amountDue ?? this.amountDue,
        lastSupplyDate: lastSupplyDate ?? this.lastSupplyDate,
        productNotes: productNotes ?? this.productNotes,
        transactions: transactions ?? this.transactions,
      );
}

// ─── MOCK DATA ──────────────────────────────────────────────────────────────

final mockProducts = <Product>[
  const Product(id: 'p1', name: 'Aashirvaad Atta 5kg', nameHi: 'आशीर्वाद आटा', category: 'Staples', price: 265, costPrice: 240, stock: 18, lowStockThreshold: 5, unit: 'bag', supplier: 'ITC Distributor'),
  const Product(id: 'p2', name: 'Tata Salt 1kg', nameHi: 'टाटा नमक', category: 'Staples', price: 24, costPrice: 20, stock: 3, lowStockThreshold: 10, unit: 'pcs', supplier: 'Tata'),
  const Product(id: 'p3', name: 'Fortune Sunflower Oil 1L', nameHi: 'फॉर्च्यून तेल', category: 'Oil', price: 145, costPrice: 128, stock: 24, lowStockThreshold: 6, unit: 'bottle', supplier: 'Adani Wilmar'),
  const Product(id: 'p4', name: 'Tata Tea Gold 250g', nameHi: 'टाटा चाय', category: 'Beverages', price: 115, costPrice: 98, stock: 2, lowStockThreshold: 5, unit: 'pkt', supplier: 'Tata'),
  Product(id: 'p5', name: 'Amul Butter 500g', nameHi: 'अमूल बटर', category: 'Dairy', price: 265, costPrice: 248, stock: 8, lowStockThreshold: 3, unit: 'pcs', supplier: 'Amul', expiryDate: DateTime.now().add(const Duration(days: 12))),
  const Product(id: 'p6', name: 'India Gate Basmati 1kg', nameHi: 'बासमती चावल', category: 'Staples', price: 135, costPrice: 112, stock: 30, lowStockThreshold: 8, unit: 'kg', supplier: 'KRBL'),
  const Product(id: 'p7', name: 'Ariel Detergent 1kg', nameHi: 'एरियल पाउडर', category: 'Household', price: 275, costPrice: 248, stock: 12, lowStockThreshold: 4, unit: 'pkt', supplier: 'P&G'),
  const Product(id: 'p8', name: 'Britannia Good Day 200g', nameHi: 'गुड डे बिस्कुट', category: 'Snacks', price: 40, costPrice: 33, stock: 4, lowStockThreshold: 10, unit: 'pkt', supplier: 'Britannia'),
  const Product(id: 'p9', name: 'Maggi Noodles 70g', nameHi: 'मैगी नूडल्स', category: 'Snacks', price: 14, costPrice: 11, stock: 48, lowStockThreshold: 15, unit: 'pcs', supplier: 'Nestle'),
  const Product(id: 'p10', name: 'Colgate MaxFresh 150g', nameHi: 'कोलगेट', category: 'Personal Care', price: 115, costPrice: 98, stock: 7, lowStockThreshold: 5, unit: 'pcs', supplier: 'Colgate'),
  const Product(id: 'p11', name: 'Moong Dal 500g', nameHi: 'मूंग दाल', category: 'Pulses', price: 72, costPrice: 60, stock: 1, lowStockThreshold: 5, unit: 'pkt', supplier: 'Local'),
  const Product(id: 'p12', name: 'Surf Excel 1kg', nameHi: 'सर्फ एक्सेल', category: 'Household', price: 295, costPrice: 265, stock: 9, lowStockThreshold: 3, unit: 'pkt', supplier: 'HUL'),
];

final mockCustomers = <Customer>[
  Customer(id: 'c1', name: 'Ramesh Sharma', phone: '9876543210', address: 'Sector 14, Near Hanuman Mandir', khata: [
    KhataEntry(id: 'k1', type: 'debit', amount: 450, note: 'Grocery items', date: DateTime.now().subtract(const Duration(days: 3))),
    KhataEntry(id: 'k2', type: 'debit', amount: 280, note: 'Atta, Dal', date: DateTime.now().subtract(const Duration(days: 1))),
  ], lastActivity: DateTime.now().subtract(const Duration(days: 1))),
  Customer(id: 'c2', name: 'Sunita Devi', phone: '9845001234', address: 'Gali 3, Rajiv Nagar', khata: [
    KhataEntry(id: 'k3', type: 'debit', amount: 1200, note: 'Monthly ration', date: DateTime.now().subtract(const Duration(days: 12))),
    KhataEntry(id: 'k4', type: 'credit', amount: 500, note: 'Part payment', date: DateTime.now().subtract(const Duration(days: 5))),
  ], lastActivity: DateTime.now().subtract(const Duration(days: 5))),
  Customer(id: 'c3', name: 'Mohit Verma', phone: '9712345678', khata: [
    KhataEntry(id: 'k5', type: 'debit', amount: 350, note: 'Oil, Biscuits', date: DateTime.now().subtract(const Duration(days: 2))),
  ], lastActivity: DateTime.now().subtract(const Duration(days: 2))),
  Customer(id: 'c4', name: 'Priya Kumari', phone: '8800112233', khata: [
    KhataEntry(id: 'k6', type: 'debit', amount: 2100, note: 'Festival shopping', date: DateTime.now().subtract(const Duration(days: 18))),
    KhataEntry(id: 'k7', type: 'credit', amount: 1000, note: 'Cash payment', date: DateTime.now().subtract(const Duration(days: 10))),
  ], lastActivity: DateTime.now().subtract(const Duration(days: 10))),
  Customer(id: 'c5', name: 'Deepak Gupta', phone: '9988776655', khata: [
    KhataEntry(id: 'k8', type: 'debit', amount: 680, note: 'Weekly items', date: DateTime.now().subtract(const Duration(days: 4))),
  ], lastActivity: DateTime.now().subtract(const Duration(days: 4))),
];

final mockOrders = <Order>[
  Order(id: 'o1', customerName: 'Ravi Kumar', customerPhone: '9900112233', address: 'H-22, New Colony', items: [BillItem(product: mockProducts[0], qty: 1), BillItem(product: mockProducts[2], qty: 2)], status: OrderStatus.pending, source: 'whatsapp', isCOD: true, createdAt: DateTime.now().subtract(const Duration(minutes: 25))),
  Order(id: 'o2', customerName: 'Anita Singh', customerPhone: '9811001100', address: 'Plot 5, Vishnu Garden', items: [BillItem(product: mockProducts[5], qty: 2), BillItem(product: mockProducts[8], qty: 5)], status: OrderStatus.packed, source: 'whatsapp', createdAt: DateTime.now().subtract(const Duration(hours: 1))),
  Order(id: 'o3', customerName: 'Suresh Yadav', customerPhone: '8700001111', items: [BillItem(product: mockProducts[3], qty: 1), BillItem(product: mockProducts[4], qty: 1)], status: OrderStatus.delivered, source: 'phone', isCOD: false, createdAt: DateTime.now().subtract(const Duration(hours: 3))),
];

final mockSuppliers = <Supplier>[
  Supplier(
    id: 's1',
    name: 'ITC Distributor',
    phone: '9811223344',
    companyName: 'ITC Limited Delhi',
    amountDue: 8500,
    lastSupplyDate: DateTime.now().subtract(const Duration(days: 5)),
    productNotes: 'Atta, Biscuits, Noodles',
    transactions: [
      SupplierTransaction(id: 'st1', type: 'supply', amount: 12000, note: 'Weekly supply', date: DateTime.now().subtract(const Duration(days: 5))),
      SupplierTransaction(id: 'st2', type: 'payment', amount: 3500, note: 'Partial payment', date: DateTime.now().subtract(const Duration(days: 3))),
    ],
  ),
  Supplier(
    id: 's2',
    name: 'Amul Agent',
    phone: '9922334455',
    companyName: 'Amul Dairy Products',
    amountDue: 3200,
    lastSupplyDate: DateTime.now().subtract(const Duration(days: 2)),
    productNotes: 'Butter, Milk, Cheese',
    transactions: [
      SupplierTransaction(id: 'st3', type: 'supply', amount: 3200, note: 'Dairy supply', date: DateTime.now().subtract(const Duration(days: 2))),
    ],
  ),
  Supplier(
    id: 's3',
    name: 'Local Vegetable Mandi',
    phone: '9700112233',
    companyName: 'Azadpur Mandi',
    amountDue: 0,
    lastSupplyDate: DateTime.now().subtract(const Duration(days: 1)),
    productNotes: 'Fresh vegetables daily',
    transactions: [
      SupplierTransaction(id: 'st4', type: 'supply', amount: 1500, note: 'Vegetables', date: DateTime.now().subtract(const Duration(days: 1))),
      SupplierTransaction(id: 'st5', type: 'payment', amount: 1500, note: 'Full payment', date: DateTime.now().subtract(const Duration(days: 1))),
    ],
  ),
];