import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum LockStatus { locked, unlocked, checking }

class AppLockState {
  final LockStatus status;
  final bool biometricEnabled;
  final bool pinEnabled;
  final bool autoLockEnabled;
  final int autoLockMinutes;
  final bool biometricAvailable;

  const AppLockState({
    this.status = LockStatus.checking,
    this.biometricEnabled = false,
    this.pinEnabled = false,
    this.autoLockEnabled = false,
    this.autoLockMinutes = 5,
    this.biometricAvailable = false,
  });

  AppLockState copyWith({
    LockStatus? status,
    bool? biometricEnabled,
    bool? pinEnabled,
    bool? autoLockEnabled,
    int? autoLockMinutes,
    bool? biometricAvailable,
  }) =>
      AppLockState(
        status: status ?? this.status,
        biometricEnabled: biometricEnabled ?? this.biometricEnabled,
        pinEnabled: pinEnabled ?? this.pinEnabled,
        autoLockEnabled: autoLockEnabled ?? this.autoLockEnabled,
        autoLockMinutes: autoLockMinutes ?? this.autoLockMinutes,
        biometricAvailable: biometricAvailable ?? this.biometricAvailable,
      );

  bool get isSecured => biometricEnabled || pinEnabled;
}

class AppLockNotifier extends StateNotifier<AppLockState> {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  static const _pinKey = 'shopiq_app_pin';
  static const _kBiometric = 'lock_biometric';
  static const _kPin = 'lock_pin_enabled';
  static const _kAutoLock = 'lock_auto';
  static const _kAutoMinutes = 'lock_minutes';

  final _auth = LocalAuthentication();

  AppLockNotifier() : super(const AppLockState()) {
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    final bioEnabled = prefs.getBool(_kBiometric) ?? false;
    final pinEnabled = prefs.getBool(_kPin) ?? false;
    final autoLock = prefs.getBool(_kAutoLock) ?? false;
    final minutes = prefs.getInt(_kAutoMinutes) ?? 5;

    bool bioAvailable = false;
    try {
      bioAvailable = await _auth.canCheckBiometrics ||
          await _auth.isDeviceSupported();
    } catch (_) {}

    if (!bioEnabled && !pinEnabled) {
      state = state.copyWith(
        status: LockStatus.unlocked,
        biometricEnabled: false,
        pinEnabled: false,
        autoLockEnabled: autoLock,
        autoLockMinutes: minutes,
        biometricAvailable: bioAvailable,
      );
      return;
    }

    state = state.copyWith(
      status: LockStatus.locked,
      biometricEnabled: bioEnabled,
      pinEnabled: pinEnabled,
      autoLockEnabled: autoLock,
      autoLockMinutes: minutes,
      biometricAvailable: bioAvailable,
    );

    if (bioEnabled && bioAvailable) {
      await authenticateWithBiometric();
    }
  }

  Future<bool> authenticateWithBiometric() async {
    try {
      final authenticated = await _auth.authenticate(
        localizedReason: 'Unlock ShopIQ to continue',
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
        ),
      );
      if (authenticated) {
        state = state.copyWith(status: LockStatus.unlocked);
      }
      return authenticated;
    } catch (_) {
      return false;
    }
  }

  Future<bool> verifyPin(String pin) async {
    try {
      final stored = await _storage.read(key: _pinKey);
      if (stored == pin) {
        state = state.copyWith(status: LockStatus.unlocked);
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<void> setPin(String pin) async {
    await _storage.write(key: _pinKey, value: pin);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kPin, true);
    state = state.copyWith(pinEnabled: true);
  }

  Future<void> removePin() async {
    await _storage.delete(key: _pinKey);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kPin, false);
    state = state.copyWith(pinEnabled: false);
  }

  Future<bool> hasPin() async {
    try {
      final pin = await _storage.read(key: _pinKey);
      return pin != null && pin.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<void> setBiometricEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kBiometric, value);
    state = state.copyWith(biometricEnabled: value);
  }

  Future<void> setAutoLock(bool enabled, {int minutes = 5}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kAutoLock, enabled);
    await prefs.setInt(_kAutoMinutes, minutes);
    state = state.copyWith(autoLockEnabled: enabled, autoLockMinutes: minutes);
  }

  void lock() {
    if (state.isSecured) {
      state = state.copyWith(status: LockStatus.locked);
    }
  }

  void unlock() => state = state.copyWith(status: LockStatus.unlocked);
}

final appLockProvider =
    StateNotifierProvider<AppLockNotifier, AppLockState>(
  (ref) => AppLockNotifier(),
);