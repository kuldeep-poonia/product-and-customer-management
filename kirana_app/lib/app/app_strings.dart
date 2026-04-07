/// Minimal localization helper for ShopIQ.
/// Add keys here and use [AppStrings.of(context)] in screens.
class AppStrings {
  const AppStrings._(this._locale);

  final String _locale;
  bool get _hi => _locale == 'hi';

  static AppStrings of(String locale) => AppStrings._(locale);

  // Navigation
  String get home => _hi ? 'होम' : 'Home';
  String get khata => _hi ? 'खाता' : 'Khata';
  String get stock => _hi ? 'स्टॉक' : 'Stock';
  String get orders => _hi ? 'ऑर्डर' : 'Orders';
  String get reports => _hi ? 'रिपोर्ट' : 'Reports';
  String get settings => _hi ? 'सेटिंग' : 'Settings';

  // Dashboard
  String get todaySale => _hi ? 'आज की बिक्री' : "Today's Sale";
  String get pendingUdhaar => _hi ? 'उधार बाकी' : 'Pending Udhaar';
  String get lowStock => _hi ? 'कम स्टॉक' : 'Low Stock';
  String get supplierDue => _hi ? 'सप्लायर बाकी' : 'Supplier Due';
  String get newOrders => _hi ? 'नए ऑर्डर' : 'New Orders';
  String get topSelling => _hi ? '🔥 टॉप सेलिंग' : '🔥 Top Selling';
  String get quickBill => _hi ? 'जल्दी बिल' : 'Quick Bill';

  // Billing
  String get searchItem => _hi ? 'आइटम खोजें...' : 'Search item...';
  String get customerName => _hi ? 'ग्राहक का नाम' : 'Customer name';
  String get mobile => _hi ? 'मोबाइल' : 'Mobile';
  String get discount => _hi ? 'छूट' : 'Discount';
  String get payVia => _hi ? 'भुगतान:' : 'Pay via:';
  String get saveBill => _hi ? 'बिल सेव करें' : 'Save Bill';
  String get billSaved => _hi ? 'बिल सेव हो गया!' : 'Bill Saved!';
  String get sendWhatsApp => _hi ? 'WhatsApp पर भेजें' : 'Send on WhatsApp';
  String get newBill => _hi ? 'नया बिल' : 'New Bill';
  String get scanBarcode => _hi ? 'बारकोड स्कैन करें' : 'Scan Barcode';

  // Inventory
  String get inventory => _hi ? 'इन्वेंटरी' : 'Inventory';
  String get addProduct => _hi ? 'प्रोडक्ट जोड़ें' : 'Add Product';
  String get searchProducts => _hi ? 'प्रोडक्ट खोजें...' : 'Search products...';
  String get outOfStock => _hi ? 'स्टॉक खत्म' : 'Out of Stock';
  String get lowStockAlert => _hi ? 'कम स्टॉक अलर्ट' : 'Low Stock Alert';

  // Khata
  String get addPayment => _hi ? 'भुगतान जोड़ें' : 'Add Payment';
  String get totalDue => _hi ? 'कुल बाकी' : 'Total Due';

  // Suppliers
  String get suppliers => _hi ? 'सप्लायर' : 'Suppliers';
  String get addSupplier => _hi ? 'सप्लायर जोड़ें' : 'Add Supplier';
  String get callSupplier => _hi ? 'कॉल करें' : 'Call';
  String get whatsappSupplier => _hi ? 'WhatsApp' : 'WhatsApp';
  String get overdueAlert => _hi ? 'अतिदेय भुगतान' : 'Overdue Payment';

  // Security
  String get appLock => _hi ? 'ऐप लॉक' : 'App Lock';
  String get biometricUnlock => _hi ? 'बायोमेट्रिक अनलॉक' : 'Biometric Unlock';
  String get setPIN => _hi ? 'PIN सेट करें' : 'Set PIN';
  String get changePIN => _hi ? 'PIN बदलें' : 'Change PIN';
  String get removePIN => _hi ? 'PIN हटाएं' : 'Remove PIN';
  String get autoLock => _hi ? 'ऑटो लॉक' : 'Auto-Lock';

  // Backup
  String get backup => _hi ? 'बैकअप' : 'Backup';
  String get backupData => _hi ? 'डेटा बैकअप करें' : 'Backup Data';
  String get restore => _hi ? 'रिस्टोर' : 'Restore';
  String get lastBackup => _hi ? 'अंतिम बैकअप' : 'Last Backup';
  String get exportData => _hi ? 'डेटा एक्सपोर्ट करें' : 'Export Data';

  // Common
  String get cancel => _hi ? 'रद्द करें' : 'Cancel';
  String get save => _hi ? 'सेव करें' : 'Save';
  String get edit => _hi ? 'संपादित करें' : 'Edit';
  String get delete => _hi ? 'हटाएं' : 'Delete';
  String get confirm => _hi ? 'पुष्टि करें' : 'Confirm';
  String get yes => _hi ? 'हाँ' : 'Yes';
  String get no => _hi ? 'नहीं' : 'No';
  String get search => _hi ? 'खोजें' : 'Search';
  String get noDataFound => _hi ? 'कोई डेटा नहीं मिला' : 'No data found';
  String get loading => _hi ? 'लोड हो रहा है...' : 'Loading...';
  String get error => _hi ? 'त्रुटि' : 'Error';
  String get success => _hi ? 'सफलता' : 'Success';
}