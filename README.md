# Budget Buddy

A local-only personal budgeting app for Android, built with Flutter and GetX.
Everything you enter stays on your device: there is no account, no sign-in, no
server and no network call anywhere in the app.

## Features

- **Onboarding** — pick one of 23 currencies and set a monthly income.
- **Categories** — create, edit and delete spending categories with a name,
  colour, icon and monthly budget limit. Each month gets its own set; the
  previous month's categories are cloned forward on first use.
- **Transactions** — add an amount, note, date and category; browse the full
  list or drill into a single category's, and delete. (There is no
  edit-in-place yet: delete and re-add.)
- **Dashboard** — monthly income, spent and remaining, a spending donut, and a
  per-category progress list. Categories turn red once they go over budget.
- **Analytics** — monthly spending bars, a per-category pie, and a savings rate,
  over "This Month", "Last 3M" or "Last 6M".
- **Settings** — change income, currency or theme (light/dark/system), or erase
  all data.

## Run it

```bash
flutter pub get
flutter run
flutter test          # 58 tests
flutter analyze       # expected: no issues
```

Requires the Flutter 3 / Dart 3 stable toolchain. Run
`dart run build_runner build --delete-conflicting-outputs` only if you change a
Hive model.

## Layout

`lib/modules/<feature>/` holds a controller + view pair per screen, backed by
`lib/data/repositories/` → `lib/services/local/` (Hive); shared theme, widgets
and utilities live in `lib/core/` and `lib/utils/`.

## For contributors: money is integer minor units

Amounts are stored and calculated as **integers in the currency's minor unit**
(`amountMinor`, `budgetLimitMinor`) — cents for USD, none for JPY. Never use
`double` for money, never hardcode `× 100` (some currencies have 0 decimal
digits): parse user input with `CurrencyUtils.parseAmount` and convert to
decimals only for display.

Hive `typeId`s and `@HiveField` indices are append-only — never renumber a live
id or reuse a retired one.
