import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../core/app_constants.dart';
import '../../core/providers.dart';
import '../../core/providers/subscription_provider.dart';

class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({super.key});

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen>
    with WidgetsBindingObserver {
  SubscriptionPlan _selectedPlan = SubscriptionPlan.yearly;
  bool _upiLaunched = false;
  bool _showUtrEntry = false;
  final _utrCtrl = TextEditingController();
  String? _utrError;
  String _lang = 'en';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _lang = ref.read(languageProvider);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _utrCtrl.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _upiLaunched && mounted) {
      setState(() {
        _upiLaunched = false;
        _showUtrEntry = true;
      });
    }
  }

  bool get _hi => _lang == 'hi';

  String get _headline => _hi ? 'ShopIQ Pro में अपग्रेड करें' : 'Upgrade to ShopIQ Pro';
  String get _subheadline => _hi
      ? 'आपका निःशुल्क ट्रायल समाप्त हो गया है।\nअपनी दुकान जारी रखने के लिए एक प्लान चुनें।'
      : 'Your free trial has ended.\nChoose a plan to continue managing your shop.';
  String get _trialExpiredBadge => _hi ? '7 दिन का ट्रायल समाप्त' : '7-Day Trial Ended';
  String get _choosePlan => _hi ? 'प्लान चुनें' : 'Choose Your Plan';
  String get _payNow => _hi ? 'UPI से भुगतान करें' : 'Pay via UPI';
  String get _enterUtr => _hi ? 'UTR नंबर दर्ज करें' : 'Enter UTR / Transaction ID';
  String get _utrHint => _hi ? 'जैसे: 407020621648' : 'e.g. 407020621648';
  String get _utrInfo => _hi
      ? 'भुगतान के बाद, UPI ऐप में Transaction ID देखें और यहाँ दर्ज करें।'
      : 'After payment, find the UTR/Transaction ID in your UPI app and enter it here.';
  String get _verifyActivate => _hi ? 'सत्यापित करें' : 'Verify';
  String get _features => _hi ? 'प्रो फीचर्स:' : 'Pro Features:';
  String get _backToPayment => _hi ? '← वापस' : '← Back';
  String get _alreadyPaid => _hi ? 'भुगतान कर दिया? UTR दर्ज करें' : 'Already paid? Enter UTR';
  String get _savingLabel => _hi ? '₹189 बचाएं!' : 'Save ₹189!';

  Future<void> _launchUpi() async {
    final sub = ref.read(subscriptionProvider.notifier);
    final link = sub.generateUpiLink(
      plan: _selectedPlan,
      userPhone: 'user',
    );

    final uri = Uri.parse(link);
    bool launched = false;

    try {
      launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}

    if (!launched) {
      if (mounted) _showManualPaymentDialog();
      return;
    }

    setState(() => _upiLaunched = true);
    HapticFeedback.mediumImpact();
  }

  void _showManualPaymentDialog() {
    final amount = _selectedPlan.price.toStringAsFixed(0);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_hi ? 'UPI से भुगतान करें' : 'Pay via UPI'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(_hi ? 'UPI ID: $kMerchantUpiId पर ₹$amount भेजें' : 'Send ₹$amount to UPI ID: $kMerchantUpiId'),
          const SizedBox(height: 16),
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: kMerchantUpiId));
              Navigator.pop(ctx);
              setState(() => _showUtrEntry = true);
            },
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(_hi ? 'बंद करें' : 'Close')),
        ],
      ),
    );
  }

  Future<void> _submitUtr() async {
    final utr = _utrCtrl.text.trim();
    if (utr.length < 10) {
      setState(() => _utrError = _hi ? 'UTR कम से कम 10 अंकों का हो' : 'UTR must be 10+ digits');
      return;
    }
    await ref.read(subscriptionProvider.notifier).submitUtr(utr);
  }

  Future<void> _verifyUtr() async {
    final ok = await ref.read(subscriptionProvider.notifier).verifySubscription();
    if (ok && mounted) {
      HapticFeedback.heavyImpact();
      showDialog(
        context: context,
        builder: (ctx) => _SuccessDialog(plan: _selectedPlan, isHindi: _hi, onDone: () => Navigator.pop(ctx)),
      );
    } else if (mounted) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Verification failed or still pending.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    _lang = ref.watch(languageProvider);
    final sub = ref.watch(subscriptionProvider);
    final cs = Theme.of(context).colorScheme;

    // ✅ SUCCESS REDIRECT: If active, go back to home
    if (sub.isActive) {
      Future.microtask(() => context.go('/'));
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (sub.isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: sub.isPending 
            ? _buildPendingView(cs, sub)
            : (_showUtrEntry ? _buildUtrEntry(cs, sub) : _buildPaywall(cs, sub)),
      ),
    );
  }

  Widget _buildPaywall(ColorScheme cs, SubscriptionState sub) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Center(
          child: Column(children: [
            const Icon(Icons.stars, color: AppColors.green600, size: 64),
            const SizedBox(height: 16),
            Text(_headline, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Text(_subheadline, textAlign: TextAlign.center, style: TextStyle(color: cs.outline)),
            const SizedBox(height: 12),
            if (sub.isExpired)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(color: AppColors.red50, borderRadius: BorderRadius.circular(20)),
                child: Text(_trialExpiredBadge, style: const TextStyle(color: AppColors.red600, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
          ]),
        ),
        const SizedBox(height: 32),
        Text(_features, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ..._features_list.map((f) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(children: [
            const Icon(Icons.check_circle, color: AppColors.green600, size: 16),
            const SizedBox(width: 8),
            Text(_hi ? f[1] : f[0], style: const TextStyle(fontSize: 13)),
          ]),
        )),
        const SizedBox(height: 32),
        _PlanCard(
          plan: SubscriptionPlan.monthly,
          selected: _selectedPlan == SubscriptionPlan.monthly,
          isHindi: _hi,
          onTap: () => setState(() => _selectedPlan = SubscriptionPlan.monthly),
        ),
        const SizedBox(height: 12),
        _PlanCard(
          plan: SubscriptionPlan.yearly,
          selected: _selectedPlan == SubscriptionPlan.yearly,
          isHindi: _hi,
          onTap: () => setState(() => _selectedPlan = SubscriptionPlan.yearly),
          badge: _savingLabel,
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _launchUpi,
            style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: Text('${_payNow} — ₹${_selectedPlan.price.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
        Center(
          child: TextButton(
            onPressed: () => setState(() => _showUtrEntry = true),
            child: Text(_alreadyPaid),
          ),
        ),
      ]),
    );
  }

  Widget _buildUtrEntry(ColorScheme cs, SubscriptionState sub) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        TextButton.icon(onPressed: () => setState(() => _showUtrEntry = false), icon: const Icon(Icons.arrow_back), label: Text(_backToPayment)),
        const SizedBox(height: 24),
        Text(_enterUtr, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(_utrInfo, style: TextStyle(color: cs.outline)),
        const SizedBox(height: 24),
        TextField(
          controller: _utrCtrl,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: 'UTR Number', errorText: _utrError, border: const OutlineInputBorder()),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _submitUtr,
            style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
            child: Text(_verifyActivate),
          ),
        ),
      ]),
    );
  }

  Widget _buildPendingView(ColorScheme cs, SubscriptionState sub) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.history_toggle_off_rounded, size: 80, color: AppColors.blue600),
        const SizedBox(height: 24),
        Text(_hi ? 'सत्यापन लंबित है' : 'Verification Pending', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Text(
          _hi 
            ? 'आपका UTR (${sub.pendingUtr}) मिल गया है। सत्यापन में 30-60 मिनट लगते हैं।'
            : 'Received UTR (${sub.pendingUtr}). Verification takes 30-60 mins.',
          textAlign: TextAlign.center,
          style: TextStyle(color: cs.outline),
        ),
        const SizedBox(height: 48),
        if (sub.isVerifying) const CircularProgressIndicator()
        else ...[
          SizedBox(
            width: double.infinity,
            child: FilledButton(onPressed: _verifyUtr, child: Text(_hi ? 'जाँच करें' : 'Check Now')),
          ),
          TextButton(onPressed: () => context.go('/'), child: Text(_hi ? 'होम पर जाएं' : 'Go to Home')),
        ],
      ]),
    );
  }

  static const _features_list = [
    ['Unlimited Bills', 'असीमित बिल'],
    ['Inventory Management', 'इन्वेंटरी मैनेजमेंट'],
    ['Khata Ledger', 'खाता लेजर'],
    ['WhatsApp Receipts', 'WhatsApp रसीदें'],
  ];
}

class _PlanCard extends StatelessWidget {
  final SubscriptionPlan plan;
  final bool selected;
  final bool isHindi;
  final VoidCallback onTap;
  final String? badge;

  const _PlanCard({required this.plan, required this.selected, required this.isHindi, required this.onTap, this.badge});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? AppColors.green600 : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? AppColors.green600 : cs.outlineVariant),
        ),
        child: Row(children: [
          Icon(selected ? Icons.radio_button_checked : Icons.radio_button_off, color: selected ? Colors.white : cs.outline),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(isHindi ? (plan == SubscriptionPlan.yearly ? 'वार्षिक' : 'मासिक') : (plan == SubscriptionPlan.yearly ? 'Yearly' : 'Monthly'),
                style: TextStyle(fontWeight: FontWeight.bold, color: selected ? Colors.white : cs.onSurface)),
            if (badge != null) Text(badge!, style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
          ])),
          Text('₹${plan.price.toStringAsFixed(0)}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: selected ? Colors.white : AppColors.green600)),
        ]),
      ),
    );
  }
}

class _SuccessDialog extends StatelessWidget {
  final SubscriptionPlan plan;
  final bool isHindi;
  final VoidCallback onDone;
  const _SuccessDialog({required this.plan, required this.isHindi, required this.onDone});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(isHindi ? 'सक्रिय हो गया!' : 'Activated!'),
      content: Text(isHindi ? 'आपका प्रो प्लान अब सक्रिय है।' : 'Your Pro plan is now active.'),
      actions: [TextButton(onPressed: onDone, child: const Text('OK'))],
    );
  }
}
