# ShopIQ — Localization

## Current Languages

- English (`en`)
- Hindi (`hi`)

## Adding a New Language

1. Create `lib/l10n/app_XX.arb` (XX = ISO language code)
2. Copy all keys from `lib/l10n/app_en.arb`
3. Translate the values — keep the key names identical
4. Add the locale to `supportedLocales` in `main.dart`
5. Add the language option to `_LanguageTile` in `settings_screen.dart`
6. Test by switching to the new language from Settings

## Key Strings Reference

| Key | English | Hindi |
|-----|---------|-------|
| `today_sales` | Today's Sale | आज की बिक्री |
| `pending_udhaar` | Pending Udhaar | बकाया उधार |
| `low_stock` | Low Stock | कम स्टॉक |
| `add_payment` | Add Payment | भुगतान जोड़ें |
| `today_profit` | Today's Profit | आज का मुनाफा |
| `quick_bill` | Quick Bill | जल्दी बिल |
| `save_bill` | Save Bill | बिल सेव करें |
| `login` | Login | लॉगिन |
| `logout` | Logout | लॉगआउट |
| `scanner` | Scanner | स्कैनर |
| `settings` | Settings | सेटिंग्स |

## Language Switch Behaviour

Language change takes effect immediately without a restart.
The selected code is persisted to SharedPreferences under the key `language`.
On next app launch, `LanguageNotifier` reads this value before the first frame renders.
