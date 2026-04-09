import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─── CONSTANTS ────────────────────────────────────────────────────────────────

/// ⚠️ REPLACE with your actual UPI ID before Play Store release.
const kMerchantUpiId = 'shopiq@okhdfcbank';

/// ⚠️ REPLACE with your registered business/name shown in UPI apps.
const kMerchantName = 'ShopIQ';

const kTrialDays = 7;
const kMonthlyPrice = 99.0;
const kYearlyPrice = 999.0;

// ─── PLAN ENUM ────────────────────────────────────────────────────────────────

enum SubscriptionPlan { monthly, yearly }

extension SubscriptionPlanX on SubscriptionPlan {
  double get price => this == SubscriptionPlan.monthly ? kMonthlyPrice : kYearlyPrice;
  int get durationDays => this == SubscriptionPlan.monthly ? 30 : 365;
  String get label => this == SubscriptionPlan.monthly ? '₹99 / Month' : '₹999 / Year';
  String get labelHi => this == SubscriptionPlan.monthly ? '₹99 / महीना' : '₹999 / साल';
  String get upiNote =>
      this == SubscriptionPlan.monthly ? 'ShopIQ Monthly Subscription' : 'ShopIQ Yearly Subscription';
}

// ─── STATUS ENUM ─────────────────────────────────────────────────────────────

enum SubscriptionStatus {
  loading,
  trial,        // Within 7-day free trial
  active,       // Paid and valid
  expired,      // Trial over + not paid
  pendingVerification, // UPI launched, awaiting UTR confirmation
}

// ─── STATE ────────────────────────────────────────────────────────────────────

class SubscriptionState {
  final SubscriptionStatus status;
  final DateTime? trialStartDate;
  final DateTime? subscriptionExpiry;
  final SubscriptionPlan? activePlan;
  final String? pendingUtr;         // UTR entered by user, awaiting verification
  final String? lastUtrVerified;
  final int trialDaysLeft;
  final bool isVerifying;

  const SubscriptionState({
    this.status = SubscriptionStatus.loading,
    this.trialStartDate,
    this.subscriptionExpiry,
    this.activePlan,
    this.pendingUtr,
    this.lastUtrVerified,
    this.trialDaysLeft = 7,
    this.isVerifying = false,
  });

  bool get isActive => status == SubscriptionStatus.active;
  bool get isTrial => status == SubscriptionStatus.trial;
  bool get isExpired => status == SubscriptionStatus.expired;
  bool get isLoading => status == SubscriptionStatus.loading;
  bool get isPending => status == SubscriptionStatus.pendingVerification;

  /// True when the app should be fully accessible (trial or paid).
  bool get hasAccess => isTrial || isActive;

  SubscriptionState copyWith({
    SubscriptionStatus? status,
    DateTime? trialStartDate,
    DateTime? subscriptionExpiry,
    SubscriptionPlan? activePlan,
    String? pendingUtr,
    String? lastUtrVerified,
    int? trialDaysLeft,
    bool? isVerifying,
  }) =>
      SubscriptionState(
        status: status ?? this.status,
        trialStartDate: trialStartDate ?? this.trialStartDate,
        subscriptionExpiry: subscriptionExpiry ?? this.subscriptionExpiry,
        activePlan: activePlan ?? this.activePlan,
        pendingUtr: pendingUtr ?? this.pendingUtr,
        lastUtrVerified: lastUtrVerified ?? this.lastUtrVerified,
        trialDaysLeft: trialDaysLeft ?? this.trialDaysLeft,
        isVerifying: isVerifying ?? this.isVerifying,
      );
}

// ─── NOTIFIER ─────────────────────────────────────────────────────────────────

class SubscriptionNotifier extends StateNotifier<SubscriptionState> {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  // SharedPreferences keys
  static const _kTrialStart       = 'sub_trial_start';
  static const _kSubExpiry        = 'sub_expiry';
  static const _kSubPlan          = 'sub_plan';
  static const _kSubActive        = 'sub_active';

  // SecureStorage keys
  static const _kUtrList          = 'sub_utrs_verified';

  SubscriptionNotifier() : super(const SubscriptionState()) {
    _init();
  }

  // ── Init ──────────────────────────────────────────────────────────────────

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();

    // ✅ FIRST CHECK FOR ACTIVE SUBSCRIPTION - even if trial was never started
    final isActive = prefs.getBool(_kSubActive) ?? false;
    if (isActive) {
      final expiryMs = prefs.getInt(_kSubExpiry);
      if (expiryMs != null) {
        final expiry = DateTime.fromMillisecondsSinceEpoch(expiryMs);
        if (expiry.isAfter(now)) {
          final planStr = prefs.getString(_kSubPlan) ?? 'monthly';
          final plan = planStr == 'yearly'
              ? SubscriptionPlan.yearly
              : SubscriptionPlan.monthly;
          
          // Get trial start if exists (optional)
          final trialStartMs = prefs.getInt(_kTrialStart);
          final trialStart = trialStartMs != null 
              ? DateTime.fromMillisecondsSinceEpoch(trialStartMs) 
              : null;

          state = state.copyWith(
            status: SubscriptionStatus.active,
            trialStartDate: trialStart,
            subscriptionExpiry: expiry,
            activePlan: plan,
            trialDaysLeft: 0,
          );
          return;
        }
        // Subscription expired
        await prefs.setBool(_kSubActive, false);
      }
    }

    // Then check trial status
    final trialStartMs = prefs.getInt(_kTrialStart);
    if (trialStartMs != null) {
      final trialStart = DateTime.fromMillisecondsSinceEpoch(trialStartMs);
      final trialEnd = trialStart.add(const Duration(days: kTrialDays));
      final daysLeft = trialEnd.difference(now).inDays.clamp(0, kTrialDays);

      if (now.isBefore(trialEnd)) {
        state = state.copyWith(
          status: SubscriptionStatus.trial,
          trialStartDate: trialStart,
          trialDaysLeft: daysLeft,
        );
      } else {
        state = state.copyWith(
          status: SubscriptionStatus.expired,
          trialStartDate: trialStart,
          trialDaysLeft: 0,
        );
      }
    } else {
      // Check for pending UTR
      final pendingUtr = prefs.getString('sub_pending_utr');
      if (pendingUtr != null) {
        state = state.copyWith(
          status: SubscriptionStatus.pendingVerification,
          pendingUtr: pendingUtr,
        );
      } else {
        // No trial and no subscription found - user is 'expired' or 'unsubscribed'
        state = state.copyWith(status: SubscriptionStatus.expired);
      }
    }
  }

  // ── Called from AuthNotifier.signUp() to start the 7-day trial ───────────

  Future<void> startTrial() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getInt(_kTrialStart);
    if (existing != null) return; // Never reset trial on re-signup

    final now = DateTime.now().millisecondsSinceEpoch;
    await prefs.setInt(_kTrialStart, now);
    state = state.copyWith(
      status: SubscriptionStatus.trial,
      trialStartDate: DateTime.fromMillisecondsSinceEpoch(now),
      trialDaysLeft: kTrialDays,
    );
  }

  // ── Activate subscription after UTR verification ─────────────────────────

  // ── Step 1: Submit UTR for verification ──────────────────────────────────
  Future<void> submitUtr(String utr) async {
    if (utr.trim().length < 10) return;
    state = state.copyWith(
      status: SubscriptionStatus.pendingVerification,
      pendingUtr: utr.trim(),
    );
    // In a real app, this would send the UTR to a server.
    // We persist it locally so it survives app restarts.
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('sub_pending_utr', utr.trim());
  }

  // ── Step 2: Finalize activation (Simulated backend approval) ──────────────
  Future<bool> verifySubscription() async {
    final utr = state.pendingUtr;
    if (utr == null) return false;

    state = state.copyWith(isVerifying: true);

    try {
      // ✅ SIMULATE REAL VERIFICATION DELAY
      // In production, this would be a polling API call to check if the 
      // admin has marked the UTR as "Paid".
      await Future.delayed(const Duration(seconds: 3));

      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      
      // Determine plan from pending data (for demo, we'll assume Monthly if not set)
      final plan = state.activePlan ?? SubscriptionPlan.monthly;
      final expiry = now.add(Duration(days: plan.durationDays));

      await prefs.setBool(_kSubActive, true);
      await prefs.setInt(_kSubExpiry, expiry.millisecondsSinceEpoch);
      await prefs.setString(_kSubPlan, plan == SubscriptionPlan.yearly ? 'yearly' : 'monthly');
      await prefs.remove('sub_pending_utr');

      // Store UTR in secure storage as receipt proof
      final existing = await _storage.read(key: _kUtrList) ?? '';
      final utrs = existing.isEmpty ? <String>[] : existing.split(',');
      utrs.add('${plan.name}:${utr}:${now.toIso8601String()}');
      await _storage.write(key: _kUtrList, value: utrs.join(','));

      state = state.copyWith(
        status: SubscriptionStatus.active,
        subscriptionExpiry: expiry,
        trialDaysLeft: 0,
        lastUtrVerified: utr,
        pendingUtr: null,
        isVerifying: false,
      );
      return true;
    } catch (_) {
      state = state.copyWith(isVerifying: false);
      return false;
    }
  }

  // Legacy method for compatibility if needed
  Future<bool> activateSubscription({
    required SubscriptionPlan plan,
    required String utr,
  }) async {
    await submitUtr(utr);
    return verifySubscription();
  }

  // ── Generate UPI deep link ────────────────────────────────────────────────

  String generateUpiLink({
    required SubscriptionPlan plan,
    required String userPhone,
  }) {
    final amount = plan.price.toStringAsFixed(2);
    final note = Uri.encodeComponent('${plan.upiNote} - $userPhone');
    final name = Uri.encodeComponent(kMerchantName);
    return 'upi://pay?pa=$kMerchantUpiId&pn=$name&am=$amount&cu=INR&tn=$note';
  }

  // ── Refresh (called on app resume) ───────────────────────────────────────

  Future<void> refresh() => _init();

  // ── Admin: reset for testing ──────────────────────────────────────────────

  Future<void> resetForTest() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kTrialStart);
    await prefs.remove(_kSubExpiry);
    await prefs.remove(_kSubPlan);
    await prefs.setBool(_kSubActive, false);
    await _storage.delete(key: _kUtrList);
    state = const SubscriptionState(status: SubscriptionStatus.loading);
  }
}

// ─── PROVIDER ─────────────────────────────────────────────────────────────────

final subscriptionProvider =
    StateNotifierProvider<SubscriptionNotifier, SubscriptionState>(
  (ref) => SubscriptionNotifier(),
);
