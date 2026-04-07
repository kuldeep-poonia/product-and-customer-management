import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'app_database.g.dart';

// Products table. Maps to the Product model.
class Products extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get nameHi => text()();
  TextColumn get category => text()();
  RealColumn get price => real()();
  RealColumn get costPrice => real()();
  IntColumn get stock => integer()();
  IntColumn get lowStockThreshold => integer()();
  TextColumn get unit => text()();
  TextColumn get supplier => text().nullable()();
  DateTimeColumn get expiryDate => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

// Customers table.
class Customers extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get phone => text()();
  TextColumn get address => text().nullable()();
  DateTimeColumn get lastActivity => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

// Khata entries (ledger rows per customer).
class KhataEntries extends Table {
  TextColumn get id => text()();
  TextColumn get customerId => text().references(Customers, #id)();
  TextColumn get type => text()(); // 'debit' or 'credit'
  RealColumn get amount => real()();
  TextColumn get note => text()();
  DateTimeColumn get date => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

// Saved bills.
class Bills extends Table {
  TextColumn get id => text()();
  TextColumn get customerId => text().nullable()();
  TextColumn get customerName => text().nullable()();
  TextColumn get customerPhone => text().nullable()();
  TextColumn get paymentMode => text()(); // cash | upi | udhaar | mixed
  RealColumn get discount => real()();
  DateTimeColumn get createdAt => dateTime()();
  BoolColumn get isPaid => boolean()();

  @override
  Set<Column> get primaryKey => {id};
}

// Individual line items inside a bill.
class BillItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get billId => text().references(Bills, #id)();
  TextColumn get productId => text()();
  TextColumn get productName => text()(); // snapshot at time of sale
  RealColumn get unitPrice => real()();
  IntColumn get qty => integer()();
}

// Orders (WhatsApp / walk-in).
class Orders extends Table {
  TextColumn get id => text()();
  TextColumn get customerName => text()();
  TextColumn get customerPhone => text()();
  TextColumn get address => text().nullable()();
  TextColumn get status => text()(); // pending | packed | outForDelivery | delivered | cancelled
  TextColumn get source => text()(); // whatsapp | walkin | phone
  BoolColumn get isCOD => boolean()();
  TextColumn get riderNote => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

// Settings key-value store. Simpler than a typed table for arbitrary settings.
class AppSettings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

// Audit log for critical user actions (bill saves, deletions, logins).
class AuditLog extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get action => text()(); // e.g. 'bill_saved', 'stock_updated'
  TextColumn get details => text()();
  DateTimeColumn get timestamp => dateTime()();
}

@DriftDatabase(tables: [
  Products,
  Customers,
  KhataEntries,
  Bills,
  BillItems,
  Orders,
  AppSettings,
  AuditLog,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  static LazyDatabase _openConnection() {
    return LazyDatabase(() async {
      final dir = await getApplicationDocumentsDirectory();
      final file = File(p.join(dir.path, 'shopiq.db'));
      return NativeDatabase(file);
    });
  }

  // Upsert a product row.
  Future<void> upsertProduct(ProductsCompanion entry) =>
      into(products).insertOnConflictUpdate(entry);

  // Get all products.
  Future<List<Product>> allProducts() => select(products).get();

  // Update stock for one product.
  Future<void> updateStock(String productId, int newStock) =>
      (update(products)..where((t) => t.id.equals(productId)))
          .write(ProductsCompanion(stock: Value(newStock)));

  // Save a bill with all its line items in one transaction.
  Future<void> saveBill(
    BillsCompanion bill,
    List<BillItemsCompanion> items,
  ) =>
      transaction(() async {
        await into(bills).insert(bill);
        await batch((b) => b.insertAll(billItems, items));
      });

  // Get all khata entries for one customer, newest first.
  Future<List<KhataEntry>> entriesForCustomer(String customerId) =>
      (select(khataEntries)
            ..where((t) => t.customerId.equals(customerId))
            ..orderBy([(t) => OrderingTerm.desc(t.date)]))
          .get();

  // Insert an audit log entry. Fire-and-forget — never block UI on this.
  Future<void> logAction(String action, String details) =>
      into(auditLog).insert(AuditLogCompanion(
        action: Value(action),
        details: Value(details),
        timestamp: Value(DateTime.now()),
      ));

  // Read a setting value by key.
  Future<String?> getSetting(String key) async {
    final row = await (select(appSettings)
          ..where((t) => t.key.equals(key)))
        .getSingleOrNull();
    return row?.value;
  }

  // Write a setting value.
  Future<void> setSetting(String key, String value) =>
      into(appSettings).insertOnConflictUpdate(
        AppSettingsCompanion(key: Value(key), value: Value(value)),
      );
}

// Singleton accessor. Providers import this instead of constructing their own.
final appDb = AppDatabase();
