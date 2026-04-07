import 'package:flutter/material.dart';

/// Hand-written localizations that mirror what flutter gen-l10n produces.
/// No build step required — just import and use [AppLocalizations.of(context)].
///
/// Usage:
///   final l = AppLocalizations.of(context)!;
///   Text(l.quickBill)
///
/// Or via extension:
///   Text(context.l10n.quickBill)

class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;
  bool get _hi => locale.languageCode == 'hi';

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = [
    delegate,
  ];

  static const List<Locale> supportedLocales = [
    Locale('en'),
    Locale('hi'),
  ];

  // ── App ────────────────────────────────────────────────────────────────────
  String get appName => 'ShopIQ';

  // ── Navigation ─────────────────────────────────────────────────────────────
  String get home => _hi ? 'होम' : 'Home';
  String get khata => _hi ? 'खाता' : 'Khata';
  String get stock => _hi ? 'स्टॉक' : 'Stock';
  String get orders => _hi ? 'ऑर्डर' : 'Orders';
  String get reports => _hi ? 'रिपोर्ट' : 'Reports';
  String get settings => _hi ? 'सेटिंग' : 'Settings';
  String get suppliers => _hi ? 'सप्लायर' : 'Suppliers';

  // ── Dashboard ──────────────────────────────────────────────────────────────
  String get todaySale => _hi ? 'आज की बिक्री' : "Today's Sale";
  String get quickBill => _hi ? 'जल्दी बिल' : 'Quick Bill';
  String get pendingUdhaar => _hi ? 'उधार बाकी' : 'Pending Udhaar';
  String get lowStock => _hi ? 'कम स्टॉक' : 'Low Stock';
  String get supplierDue => _hi ? 'सप्लायर बाकी' : 'Supplier Due';
  String get newOrders => _hi ? 'नए ऑर्डर' : 'New Orders';
  String get topSelling => _hi ? '🔥 टॉप सेलिंग' : '🔥 Top Selling';
  String get lowStockAlerts => _hi ? '⚠️ कम स्टॉक अलर्ट' : '⚠️ Low Stock Alerts';
  String get overdueKhata => _hi ? '🔴 बकाया खाता' : '🔴 Overdue Khata';
  String get seeAll => _hi ? 'सभी देखें' : 'See All';
  String get addStock => _hi ? 'स्टॉक जोड़ें' : 'Add Stock';

  // ── Billing ────────────────────────────────────────────────────────────────
  String get searchItem => _hi ? 'आइटम खोजें... (जैसे आटा, टाटा)' : 'Search item... (e.g. Atta, Tata)';
  String get customerName => _hi ? 'ग्राहक का नाम' : 'Customer name';
  String get mobile => _hi ? 'मोबाइल' : 'Mobile';
  String get discount => _hi ? 'छूट' : 'Discount';
  String get payVia => _hi ? 'भुगतान:' : 'Pay via:';
  String get saveBill => _hi ? 'बिल सेव करें' : 'Save Bill';
  String get saving => _hi ? 'सेव हो रहा है...' : 'Saving...';
  String get billSaved => _hi ? 'बिल सेव हो गया!' : 'Bill Saved!';
  String get newBill => _hi ? 'नया बिल' : 'New Bill';
  String get scanBarcode => _hi ? 'बारकोड स्कैन करें' : 'Scan Barcode';
  String get billIsEmpty => _hi ? 'बिल खाली है' : 'Bill is empty';
  String get searchAndAddItems => _hi ? 'ऊपर से आइटम खोजें और जोड़ें' : 'Search and add items above';
  String get total => _hi ? 'कुल' : 'Total';
  String get subtotal => _hi ? 'उपकुल' : 'Subtotal';
  String get sendOnWhatsApp => _hi ? 'WhatsApp पर भेजें' : 'Send on WhatsApp';
  String get clear => _hi ? 'साफ करें' : 'Clear';
  String get cash => _hi ? 'नकद' : 'Cash';
  String get upi => 'UPI';
  String get udhaar => _hi ? 'उधार' : 'Udhaar';
  String get mixed => _hi ? 'मिश्रित' : 'Mixed';

  // ── Inventory ──────────────────────────────────────────────────────────────
  String get inventory => _hi ? 'इन्वेंटरी' : 'Inventory';
  String get addProduct => _hi ? 'प्रोडक्ट जोड़ें' : 'Add Product';
  String get searchProducts => _hi ? 'प्रोडक्ट खोजें...' : 'Search products...';
  String get outOfStock => _hi ? 'स्टॉक खत्म' : 'Out of Stock';

  // ── Khata ──────────────────────────────────────────────────────────────────
  String get addPayment => _hi ? 'भुगतान जोड़ें' : 'Add Payment';
  String get totalDue => _hi ? 'कुल बाकी' : 'Total Due';

  // ── Orders ─────────────────────────────────────────────────────────────────
  String get ordersDelivery => _hi ? 'ऑर्डर और डिलीवरी' : 'Orders & Delivery';
  String get pending => _hi ? 'लंबित' : 'Pending';
  String get packed => _hi ? 'पैक हो गया' : 'Packed';
  String get onWay => _hi ? 'रास्ते में' : 'On Way';
  String get delivered => _hi ? 'पहुंच गया' : 'Delivered';
  String get markPacked => _hi ? 'पैक करें' : 'Mark Packed';
  String get outForDelivery => _hi ? 'डिलीवरी पर भेजें' : 'Out for Delivery';
  String get markDelivered => _hi ? 'डिलीवर हो गया' : 'Mark Delivered';

  // ── Suppliers ──────────────────────────────────────────────────────────────
  String get addSupplier => _hi ? 'सप्लायर जोड़ें' : 'Add Supplier';
  String get callSupplier => _hi ? 'कॉल करें' : 'Call';
  String get overdueAlert => _hi ? 'अतिदेय भुगतान' : 'Overdue Payment';

  // ── Security ───────────────────────────────────────────────────────────────
  String get appLock => _hi ? 'ऐप लॉक' : 'App Lock';
  String get biometricUnlock => _hi ? 'बायोमेट्रिक अनलॉक' : 'Biometric Unlock';
  String get setPIN => _hi ? 'PIN लॉक सेट करें' : 'Set PIN Lock';
  String get changePIN => _hi ? 'PIN बदलें' : 'Change PIN';
  String get removePIN => _hi ? 'PIN हटाएं' : 'Remove PIN';
  String get autoLock => _hi ? 'ऑटो लॉक' : 'Auto-Lock';
  String get pinActive => _hi ? 'PIN लॉक चालू है' : 'PIN Lock (Active)';
  String get biometricActive => _hi ? 'फिंगरप्रिंट/Face ID चालू' : 'Fingerprint/Face ID active';

  // ── Backup ─────────────────────────────────────────────────────────────────
  String get backup => _hi ? 'बैकअप' : 'Backup';
  String get backupData => _hi ? 'डेटा बैकअप करें' : 'Backup Data';
  String get restore => _hi ? 'रिस्टोर करें' : 'Restore';
  String get lastBackup => _hi ? 'अंतिम बैकअप' : 'Last Backup';
  String get exportData => _hi ? 'डेटा एक्सपोर्ट करें' : 'Export Data';

  // ── Settings ───────────────────────────────────────────────────────────────
  String get appearance => _hi ? 'दिखावट' : 'Appearance';
  String get darkMode => _hi ? 'डार्क मोड' : 'Dark Mode';
  String get darkModeOn => _hi ? 'चालू है' : 'Currently on';
  String get darkModeOff => _hi ? 'बंद है' : 'Currently off';
  String get languageLabel => _hi ? 'भाषा / Language' : 'Language / भाषा';
  String get shopName => _hi ? 'दुकान का नाम' : 'Shop Name';
  String get location => _hi ? 'पता' : 'Location';
  String get security => _hi ? 'सुरक्षा' : 'Security';
  String get about => _hi ? 'जानकारी' : 'About';
  String get version => _hi ? 'वर्शन' : 'Version';
  String get privacyPolicy => _hi ? 'गोपनीयता नीति' : 'Privacy Policy';
  String get logout => _hi ? 'लॉगआउट' : 'Logout';
  String get logoutConfirmTitle => _hi ? 'लॉगआउट करें?' : 'Logout?';
  String get logoutConfirmMsg => _hi ? 'क्या आप वाकई लॉगआउट करना चाहते हैं? आपका स्थानीय डेटा इस डिवाइस पर रहेगा।' : 'Are you sure you want to logout? Your local data will remain on this device.';
  String get backupRestore => _hi ? 'बैकअप और डेटा' : 'Backup & Data';
  String get shopInfo => _hi ? 'दुकान की जानकारी' : 'Shop Info';
  String get exportToStorage => _hi ? 'लोकल स्टोरेज / शेयर करें' : 'Export to local storage / share';
  String get restoreFromBackup => _hi ? 'पिछले बैकअप से रिस्टोर करें' : 'Restore from a previous backup';

  // ── Common ─────────────────────────────────────────────────────────────────
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
  String get success => _hi ? 'सफलता!' : 'Success!';
  String get customers => _hi ? 'ग्राहक' : 'Customers';
  String get noItemsFound => _hi ? 'कोई आइटम नहीं मिला' : 'No items found';
}

// ── Delegate ─────────────────────────────────────────────────────────────────

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      ['en', 'hi'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async =>
      AppLocalizations(locale);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

// ── BuildContext extension ────────────────────────────────────────────────────

extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n =>
      AppLocalizations.of(this) ?? AppLocalizations(const Locale('en'));
}