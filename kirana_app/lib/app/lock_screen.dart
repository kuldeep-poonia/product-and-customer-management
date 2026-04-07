import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme.dart';
import '../../core/app_constants.dart';
import 'app_lock_provider.dart';
/// Full-screen lock overlay shown when [AppLockState.status] == locked.
class LockScreen extends ConsumerStatefulWidget {
  const LockScreen({super.key});

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen>
    with SingleTickerProviderStateMixin {
  final List<String> _pin = [];
  bool _error = false;
  bool _loading = false;
  late AnimationController _shakeCtrl;
  late Animation<double> _shakeAnim;

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnim = Tween(begin: 0.0, end: 12.0)
        .chain(CurveTween(curve: Curves.elasticIn))
        .animate(_shakeCtrl);
  }

  @override
  void dispose() {
    _shakeCtrl.dispose();
    super.dispose();
  }

  void _onKey(String key) {
    if (_loading) return;
    if (key == 'del') {
      if (_pin.isNotEmpty) setState(() { _pin.removeLast(); _error = false; });
      return;
    }
    if (_pin.length >= 4) return;
    setState(() {
      _pin.add(key);
      _error = false;
    });
    if (_pin.length == 4) _verifyPin();
  }

  Future<void> _verifyPin() async {
    setState(() => _loading = true);
    final ok = await ref.read(appLockProvider.notifier).verifyPin(_pin.join());
    if (!mounted) return;
    if (!ok) {
      HapticFeedback.heavyImpact();
      _shakeCtrl.forward(from: 0);
      setState(() { _error = true; _loading = false; _pin.clear(); });
    } else {
      setState(() => _loading = false);
    }
  }

  Future<void> _tryBiometric() async {
    setState(() => _loading = true);
    await ref.read(appLockProvider.notifier).authenticateWithBiometric();
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final lockState = ref.watch(appLockProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 56),
            // Logo
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.green600, AppColors.green700],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: AppColors.green600.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 6))],
              ),
              alignment: Alignment.center,
              child: const Text('IQ',
                  style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900)),
            ),
            const SizedBox(height: 16),
            const Text(AppConstants.appName,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text(
              lockState.biometricEnabled ? 'Use biometric or enter PIN' : 'Enter 4-digit PIN',
              style: TextStyle(fontSize: 14, color: cs.outline),
            ),
            const SizedBox(height: 36),

            // PIN dots with shake animation on error
            AnimatedBuilder(
              animation: _shakeAnim,
              builder: (_, child) => Transform.translate(
                offset: Offset(_error ? _shakeAnim.value * ((_pin.length % 2 == 0) ? 1 : -1) : 0, 0),
                child: child,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (i) {
                  final filled = i < _pin.length;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _error
                          ? AppColors.red600
                          : filled
                              ? AppColors.green600
                              : cs.outlineVariant,
                      border: Border.all(
                        color: filled || _error ? Colors.transparent : cs.outlineVariant,
                        width: 1.5,
                      ),
                    ),
                  );
                }),
              ),
            ),
            if (_error) ...[
              const SizedBox(height: 12),
              const Text('Wrong PIN. Try again.',
                  style: TextStyle(color: AppColors.red600, fontSize: 13)),
            ],

            const Spacer(),

            // Number pad
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final row in [
                    ['1', '2', '3'],
                    ['4', '5', '6'],
                    ['7', '8', '9'],
                    [lockState.biometricEnabled && lockState.biometricAvailable ? 'bio' : '', '0', 'del'],
                  ])
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: row.map((k) => _PinKey(
                        label: k,
                        loading: _loading,
                        onTap: k.isEmpty ? null : () {
                          if (k == 'bio') {
                            _tryBiometric();
                          } else {
                            _onKey(k);
                          }
                        },
                      )).toList(),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }
}

class _PinKey extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback? onTap;
  const _PinKey({required this.label, required this.loading, this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (label.isEmpty) return const SizedBox(width: 72, height: 72);

    Widget child;
    if (label == 'del') {
      child = Icon(Icons.backspace_outlined, size: 22, color: cs.onSurface);
    } else if (label == 'bio') {
      child = const Icon(Icons.fingerprint, size: 30, color: AppColors.green600);
    } else {
      child = Text(label, style: TextStyle(fontSize: 26, fontWeight: FontWeight.w500, color: cs.onSurface));
    }

    return GestureDetector(
      onTap: loading ? null : onTap,
      child: Container(
        width: 72,
        height: 72,
        margin: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: child,
      ),
    );
  }
}

/// PIN setup flow shown from settings.
class SetPinScreen extends ConsumerStatefulWidget {
  const SetPinScreen({super.key});

  @override
  ConsumerState<SetPinScreen> createState() => _SetPinScreenState();
}

class _SetPinScreenState extends ConsumerState<SetPinScreen> {
  final List<String> _pin = [];
  final List<String> _confirm = [];
  bool _confirming = false;
  bool _error = false;
  bool _saved = false;

  void _onKey(String key) {
    final current = _confirming ? _confirm : _pin;
    if (key == 'del') {
      if (current.isNotEmpty) setState(() { current.removeLast(); _error = false; });
      return;
    }
    if (current.length >= 4) return;
    setState(() { current.add(key); _error = false; });

    if (current.length == 4) {
      if (!_confirming) {
        setState(() => _confirming = true);
      } else {
        _checkMatch();
      }
    }
  }

  void _checkMatch() {
    if (_pin.join() == _confirm.join()) {
      ref.read(appLockProvider.notifier).setPin(_pin.join()).then((_) {
        setState(() => _saved = true);
        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted) Navigator.pop(context, true);
        });
      });
    } else {
      HapticFeedback.heavyImpact();
      setState(() { _error = true; _confirm.clear(); });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final current = _confirming ? _confirm : _pin;
    final title = _saved ? 'PIN Saved! ✓' : _confirming ? 'Confirm PIN' : 'Set 4-digit PIN';

    return Scaffold(
      appBar: AppBar(title: const Text('Set PIN'), centerTitle: true),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 40),
            Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(
              _error ? 'PINs do not match. Try again.' : '',
              style: const TextStyle(color: AppColors.red600, fontSize: 13),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (i) {
                final filled = i < current.length;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  width: 16, height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _saved ? AppColors.green600 : _error ? AppColors.red600 : filled ? AppColors.green600 : cs.outlineVariant,
                  ),
                );
              }),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final row in [['1','2','3'],['4','5','6'],['7','8','9'],['','0','del']])
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: row.map((k) => _PinKey(
                        label: k,
                        loading: _saved,
                        onTap: k.isEmpty ? null : () => _onKey(k),
                      )).toList(),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }
}