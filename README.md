# Budget Buddy

A local-only personal budgeting app for Android, built with Flutter and GetX.
Everything you enter stays on your device: there is no account, no sign-in, no
server and no network call anywhere in the app.

## Features

- **Onboarding** — pick one of 23 currencies and set a monthly income (which you
  may skip). Nine starter categories are created, with limits sized to that
  income, or to the presets' own figures if you skipped it.
- **Categories** — create, edit and delete spending categories with a name,
  colour, icon and monthly budget limit. Each month gets its own set; the
  previous month's categories are cloned forward on first use. Deleting one
  keeps its transactions — they move to a reserved "Uncategorised" category.
- **Transactions** — add an amount, note, date and category; browse the full
  list or drill into a single category's; tap any row to edit it, or delete it
  after a confirmation that names the amount.
- **Dashboard** — your monthly income, with spent and remaining for the month on
  screen, a budgets card, the most recent transactions and a spending donut;
  chevrons at the top browse earlier months. A category warns at 75% of its limit and again once it
  is over, and each state says so in words as well as colour — how much is
  left, or how much it is over.
- **Analytics** — monthly spending bars, a per-category pie, and a savings rate,
  over "This Month", "Last 3M" or "Last 6M".
- **Settings** — change income, currency or theme (light/dark/system), export
  every transaction as a CSV file, or erase all data.

## Run it

```bash
flutter pub get
flutter run
flutter test          # 423 tests, all green as of 2026-08-06
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
