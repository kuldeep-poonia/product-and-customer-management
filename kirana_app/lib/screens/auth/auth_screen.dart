import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../app/theme.dart';
import '../../core/app_constants.dart';

// ─── AUTH STATE ───────────────────────────────────────────────────────────────

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState {
  final AuthStatus status;
  final String? shopName;
  final String? ownerName;
  final String? ownerPhone;
  final String? errorMessage;
  final bool isLoading;

  const AuthState({
    required this.status,
    this.shopName,
    this.ownerName,
    this.ownerPhone,
    this.errorMessage,
    this.isLoading = false,
  });

  AuthState copyWith({
    AuthStatus? status,
    String? shopName,
    String? ownerName,
    String? ownerPhone,
    String? errorMessage,
    bool clearError = false,
    bool? isLoading,
  }) =>
      AuthState(
        status: status ?? this.status,
        shopName: shopName ?? this.shopName,
        ownerName: ownerName ?? this.ownerName,
        ownerPhone: ownerPhone ?? this.ownerPhone,
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
        isLoading: isLoading ?? this.isLoading,
      );
}

// ─── AUTH NOTIFIER ────────────────────────────────────────────────────────────

class AuthNotifier extends StateNotifier<AuthState> {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  static const _kPin = 'shopiq_owner_pin';
  static const _kPhone = 'shopiq_owner_phone';
  static const _kShop = 'shopiq_shop_name';
  static const _kOwner = 'shopiq_owner_name';
  static const _kLoggedIn = 'shopiq_logged_in';

  final _localAuth = LocalAuthentication();

  AuthNotifier() : super(const AuthState(status: AuthStatus.unknown)) {
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool(_kLoggedIn) ?? false;
      if (!isLoggedIn) {
        state = state.copyWith(status: AuthStatus.unauthenticated);
        return;
      }
      final phone = await _storage.read(key: _kPhone) ?? '';
      final shopName = prefs.getString(_kShop) ?? AppConstants.defaultShopName;
      final ownerName = prefs.getString(_kOwner) ?? '';
      state = AuthState(
        status: AuthStatus.authenticated,
        ownerPhone: phone,
        shopName: shopName,
        ownerName: ownerName,
      );
    } catch (_) {
      state = state.copyWith(status: AuthStatus.unauthenticated);
    }
  }

  Future<bool> isSignedUp() async {
    try {
      final pin = await _storage.read(key: _kPin);
      return pin != null && pin.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<void> signUp({
    required String phone,
    required String shopName,
    required String ownerName,
    required String pin,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _storage.write(key: _kPin, value: pin);
      await _storage.write(key: _kPhone, value: phone);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kShop, shopName);
      await prefs.setString(_kOwner, ownerName);
      await prefs.setBool(_kLoggedIn, true);
      state = AuthState(
        status: AuthStatus.authenticated,
        ownerPhone: phone,
        shopName: shopName,
        ownerName: ownerName,
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Signup failed. Please try again.',
      );
    }
  }

  Future<void> login(String phone, String pin) async {
    state = state.copyWith(isLoading: true, clearError: true);
    if (phone.length != 10) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Enter a valid 10-digit mobile number.',
      );
      return;
    }
    if (pin.length < 4) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'PIN must be at least 4 digits.',
      );
      return;
    }
    try {
      final storedPin = await _storage.read(key: _kPin);
      final storedPhone = await _storage.read(key: _kPhone);
      if (storedPin == null) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'No account found. Please sign up first.',
        );
        return;
      }
      if (storedPin != pin || (storedPhone != null && storedPhone != phone)) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Incorrect phone number or PIN.',
        );
        return;
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kLoggedIn, true);
      final shopName = prefs.getString(_kShop) ?? AppConstants.defaultShopName;
      final ownerName = prefs.getString(_kOwner) ?? '';
      state = AuthState(
        status: AuthStatus.authenticated,
        ownerPhone: phone,
        shopName: shopName,
        ownerName: ownerName,
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Login failed. Please try again.',
      );
    }
  }

  Future<bool> loginWithBiometric() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isSupported = await _localAuth.isDeviceSupported();
      if (!canCheck && !isSupported) return false;
      final ok = await _localAuth.authenticate(
        localizedReason: 'Use biometrics to login to ShopIQ',
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
          sensitiveTransaction: false,
        ),
      );
      if (!ok) return false;
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool(_kLoggedIn) ?? false;
      if (!isLoggedIn) return false;
      final phone = await _storage.read(key: _kPhone) ?? '';
      final shopName = prefs.getString(_kShop) ?? AppConstants.defaultShopName;
      final ownerName = prefs.getString(_kOwner) ?? '';
      state = AuthState(
        status: AuthStatus.authenticated,
        ownerPhone: phone,
        shopName: shopName,
        ownerName: ownerName,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kLoggedIn, false);
    } catch (_) {}
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  Future<void> resetAccount() async {
    try {
      await _storage.deleteAll();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kLoggedIn);
      await prefs.remove(_kShop);
      await prefs.remove(_kOwner);
    } catch (_) {}
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  Future<bool> get biometricAvailable async {
    try {
      return await _localAuth.canCheckBiometrics ||
          await _localAuth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }
}

final authProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) => AuthNotifier());

// ─── LOGIN SCREEN ─────────────────────────────────────────────────────────────

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _phoneCtrl = TextEditingController();
  final _pinCtrl = TextEditingController();
  bool _pinVisible = false;
  bool _isSignup = false;
  bool _bioAvailable = false;
  bool _checked = false;

  @override
  void initState() {
    super.initState();
    _checkSetup();
  }

  Future<void> _checkSetup() async {
    final notifier = ref.read(authProvider.notifier);
    final hasAccount = await notifier.isSignedUp();
    final bio = await notifier.biometricAvailable;
    if (!mounted) return;
    setState(() {
      _isSignup = !hasAccount;
      _bioAvailable = bio && hasAccount;
      _checked = true;
    });
    if (hasAccount) {
      try {
        const st = FlutterSecureStorage(
          aOptions: AndroidOptions(encryptedSharedPreferences: true),
        );
        final phone = await st.read(key: 'shopiq_owner_phone');
        if (phone != null && mounted) _phoneCtrl.text = phone;
      } catch (_) {}
    }
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (_isSignup) {
      final result = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
            builder: (_) => SignupScreen(phone: _phoneCtrl.text.trim())),
      );
      if (result == true && mounted) context.go('/');
      return;
    }
    await ref.read(authProvider.notifier).login(
          _phoneCtrl.text.trim(),
          _pinCtrl.text.trim(),
        );
    final auth = ref.read(authProvider);
    if (auth.status == AuthStatus.authenticated && mounted) context.go('/');
  }

  Future<void> _biometricLogin() async {
    final ok = await ref.read(authProvider.notifier).loginWithBiometric();
    if (ok && mounted) context.go('/');
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _pinCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final cs = Theme.of(context).colorScheme;

    if (!_checked) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 48),
              Center(
                child: Column(children: [
                  Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.green600, AppColors.green700],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [BoxShadow(color: AppColors.green600.withOpacity(0.35), blurRadius: 20, offset: const Offset(0, 8))],
                    ),
                    alignment: Alignment.center,
                    child: const Text('IQ', style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w900)),
                  ),
                  const SizedBox(height: 16),
                  const Text(AppConstants.appName, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(AppConstants.appTagline, style: TextStyle(fontSize: 13, color: cs.outline)),
                ]),
              ),
              const SizedBox(height: 52),
              Text(_isSignup ? 'Create Account' : 'Welcome back!',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(_isSignup ? 'Set up your shop account' : 'Login to manage your shop',
                  style: TextStyle(fontSize: 14, color: cs.outline)),
              const SizedBox(height: 28),
              TextField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
                decoration: InputDecoration(
                  labelText: 'Mobile Number',
                  hintText: '9876543210',
                  prefixIcon: const Icon(Icons.phone_outlined),
                  prefixText: '+91  ',
                  filled: true,
                  fillColor: cs.surfaceContainerHighest.withOpacity(0.4),
                ),
              ),
              if (!_isSignup) ...[
                const SizedBox(height: 14),
                TextField(
                  controller: _pinCtrl,
                  obscureText: !_pinVisible,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
                  onSubmitted: (_) => _submit(),
                  decoration: InputDecoration(
                    labelText: 'PIN',
                    hintText: '••••',
                    prefixIcon: const Icon(Icons.lock_outline),
                    filled: true,
                    fillColor: cs.surfaceContainerHighest.withOpacity(0.4),
                    suffixIcon: IconButton(
                      icon: Icon(_pinVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                      onPressed: () => setState(() => _pinVisible = !_pinVisible),
                    ),
                  ),
                ),
              ],
              if (auth.errorMessage != null) ...[
                const SizedBox(height: 12),
                _AuthErrorBox(message: auth.errorMessage!),
              ],
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: auth.isLoading ? null : _submit,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: auth.isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(_isSignup ? 'Continue →' : 'Login',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
              if (!_isSignup && _bioAvailable) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _biometricLogin,
                    icon: const Icon(Icons.fingerprint, size: 22),
                    label: const Text('Login with Biometric', style: TextStyle(fontWeight: FontWeight.w600)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Center(
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(_isSignup ? 'Already have an account? ' : 'New here? ',
                      style: TextStyle(color: cs.outline, fontSize: 13)),
                  GestureDetector(
                    onTap: () => setState(() => _isSignup = !_isSignup),
                    child: Text(_isSignup ? 'Login' : 'Create account',
                        style: TextStyle(color: cs.primary, fontSize: 13, fontWeight: FontWeight.w700)),
                  ),
                ]),
              ),
              if (!_isSignup) ...[
                const SizedBox(height: 8),
                Center(
                  child: TextButton(
                    onPressed: () => _showForgotPin(context),
                    child: Text('Forgot PIN?', style: TextStyle(color: cs.outline, fontSize: 13)),
                  ),
                ),
              ],
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  void _showForgotPin(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Account'),
        content: const Text('This will clear your login PIN. Your shop data (bills, inventory, khata) stays on this device.\n\nYou will need to sign up again.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(authProvider.notifier).resetAccount();
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.red600),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
}

// ─── SIGNUP SCREEN ────────────────────────────────────────────────────────────

class SignupScreen extends ConsumerStatefulWidget {
  final String phone;
  const SignupScreen({super.key, required this.phone});
  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _pageCtrl = PageController();
  int _page = 0;
  late final TextEditingController _phoneCtrl;
  final _shopCtrl = TextEditingController();
  final _ownerCtrl = TextEditingController();
  final List<String> _pin = [];
  final List<String> _confirmPin = [];
  bool _confirming = false;
  bool _pinError = false;

  @override
  void initState() {
    super.initState();
    _phoneCtrl = TextEditingController(text: widget.phone);
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _phoneCtrl.dispose();
    _shopCtrl.dispose();
    _ownerCtrl.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_shopCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter your shop name'), behavior: SnackBarBehavior.floating));
      return;
    }
    if (_ownerCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter your name'), behavior: SnackBarBehavior.floating));
      return;
    }
    if (_phoneCtrl.text.trim().length != 10) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a valid 10-digit mobile number'), behavior: SnackBarBehavior.floating));
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _page = 1);
    _pageCtrl.animateToPage(1, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
  }

  void _onPinKey(String key) {
    final current = _confirming ? _confirmPin : _pin;
    if (key == 'del') {
      if (current.isNotEmpty) setState(() { current.removeLast(); _pinError = false; });
      return;
    }
    if (current.length >= 4) return;
    setState(() { current.add(key); _pinError = false; });
    if (current.length == 4) {
      if (!_confirming) {
        Future.delayed(const Duration(milliseconds: 200), () => setState(() => _confirming = true));
      } else {
        _checkPinMatch();
      }
    }
  }

  Future<void> _checkPinMatch() async {
    if (_pin.join() != _confirmPin.join()) {
      HapticFeedback.heavyImpact();
      setState(() { _pinError = true; _confirmPin.clear(); });
      return;
    }
    await ref.read(authProvider.notifier).signUp(
      phone: _phoneCtrl.text.trim(),
      shopName: _shopCtrl.text.trim(),
      ownerName: _ownerCtrl.text.trim(),
      pin: _pin.join(),
    );
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(_page == 0 ? 'Shop Setup (1/2)' : 'Create PIN (2/2)'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_page == 1) {
              setState(() { _page = 0; _pin.clear(); _confirmPin.clear(); _confirming = false; _pinError = false; });
              _pageCtrl.animateToPage(0, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: Column(children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.5, end: _page == 0 ? 0.5 : 1.0),
          duration: const Duration(milliseconds: 300),
          builder: (_, v, __) => LinearProgressIndicator(value: v, backgroundColor: cs.surfaceContainerHighest),
        ),
        Expanded(
          child: PageView(
            controller: _pageCtrl,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              // ── Page 1: Details ──────────────────────────────────────────
              SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const SizedBox(height: 8),
                  const Text('Tell us about your shop', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text('Appears on bills & receipts', style: TextStyle(fontSize: 14, color: cs.outline)),
                  const SizedBox(height: 32),
                  _Field(ctrl: _phoneCtrl, label: 'Mobile Number', hint: '9876543210', icon: Icons.phone_outlined,
                    keyboard: TextInputType.phone, formatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)]),
                  const SizedBox(height: 16),
                  _Field(ctrl: _shopCtrl, label: 'Shop / Business Name', hint: 'e.g. Jai Mata Di Kirana', icon: Icons.store_outlined, keyboard: TextInputType.name),
                  const SizedBox(height: 16),
                  _Field(ctrl: _ownerCtrl, label: 'Your Name', hint: 'e.g. Ramesh Kumar', icon: Icons.person_outline, keyboard: TextInputType.name),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _nextPage,
                      style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                      child: const Text('Continue →', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ]),
              ),
              // ── Page 2: PIN ──────────────────────────────────────────────
              SafeArea(
                child: Column(children: [
                  const SizedBox(height: 32),
                  Text(_confirming ? 'Confirm your PIN' : 'Create 4-digit PIN',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  Text(_confirming ? 'Re-enter the same PIN' : 'Keeps your ShopIQ account secure',
                      style: TextStyle(fontSize: 14, color: cs.outline)),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(4, (i) {
                      final dots = _confirming ? _confirmPin : _pin;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        margin: const EdgeInsets.symmetric(horizontal: 12),
                        width: 18, height: 18,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _pinError ? AppColors.red600 : i < dots.length ? cs.primary : cs.outlineVariant,
                        ),
                      );
                    }),
                  ),
                  if (_pinError) ...[
                    const SizedBox(height: 10),
                    const Text('PINs do not match. Try again.', style: TextStyle(color: AppColors.red600, fontSize: 13)),
                  ],
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 48),
                    child: Column(children: [
                      for (final row in [['1','2','3'],['4','5','6'],['7','8','9'],['','0','del']])
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: row.map((k) => k.isEmpty
                            ? const SizedBox(width: 72, height: 72)
                            : _PinKey(label: k, onTap: () => _onPinKey(k))
                          ).toList(),
                        ),
                    ]),
                  ),
                  const SizedBox(height: 32),
                ]),
              ),
            ],
          ),
        ),
      ]),
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

class _Field extends StatelessWidget {
  final TextEditingController ctrl;
  final String label, hint;
  final IconData icon;
  final TextInputType keyboard;
  final List<TextInputFormatter>? formatters;
  const _Field({required this.ctrl, required this.label, required this.hint, required this.icon, required this.keyboard, this.formatters});
  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboard,
      inputFormatters: formatters,
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(labelText: label, hintText: hint, prefixIcon: Icon(icon), filled: true, fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.4)),
    );
  }
}

class _PinKey extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _PinKey({required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 72, height: 72,
        margin: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(color: cs.surfaceContainerHighest, shape: BoxShape.circle),
        alignment: Alignment.center,
        child: label == 'del'
          ? Icon(Icons.backspace_outlined, size: 22, color: cs.onSurface)
          : Text(label, style: TextStyle(fontSize: 26, fontWeight: FontWeight.w500, color: cs.onSurface)),
      ),
    );
  }
}

class _AuthErrorBox extends StatelessWidget {
  final String message;
  const _AuthErrorBox({required this.message});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.red50, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.red400.withOpacity(0.3))),
      child: Row(children: [
        const Icon(Icons.error_outline, color: AppColors.red600, size: 18),
        const SizedBox(width: 8),
        Expanded(child: Text(message, style: const TextStyle(color: AppColors.red600, fontSize: 13))),
      ]),
    );
  }
}