# WG App

A shared-household app for flatmates (WG): **list what is missing, do the shopping, split the cost automatically.**

Built with Flutter (web first, Android/iOS from the same code later) and Supabase. German, English and Turkish UI.

<!-- TODO: live link once deployed (see "Yayin" block in docs/PLAN.md) -->
<!-- TODO: screenshots (shopping list, expenses, balances, light + dark) -->

## What it does

- **Shared shopping list** for things that ran out at home. Updates in real time and is visible only to the group.
- **Expenses** entered by whoever paid: amount, who is covered, optional items from the list. Split equally, by ratio (2:1:1) or by exact amounts.
- **Quick item picker:** ready-made catalog (German/English/Turkish, umlaut- and accent-insensitive search), the group's most-used items, free-text items.
- **Balances** and the fewest transfers needed to settle up, with a "mark as paid" flow and a monthly summary.
- **Flatmates moving in and out:** someone who leaves stays in past expenses and keeps their open balance until it is settled.
- Invite links (`/join/<code>`), admin handover, light and dark theme, installable as a PWA.

## Why not just Splitwise?

Splitwise is great at splitting costs, but a flat's day-to-day is: "we're out of toilet paper" -> someone buys it -> someone has to pay it back. As far as I know there is no shopping list in that flow. Here the list and the expense live in one place: mark things as bought on the list, attach the products to the expense, and the split follows. The group model also fits a WG: people move in and move out, and history must not break when they do.

It is also a learning project, built to be small enough to finish and clean enough to explain.

## Design decisions

- **Money is always an `int` in cents.** `23,50 EUR` is `2350`. No `double` ever touches money. Parsing and formatting live in one file (`lib/core/money.dart`).
- **Balances are computed, never stored.** `balance = paid - own shares + settlements sent - settlements received`, recalculated from expenses, shares and settlements. There is no balance column that can drift out of sync, and the sum of all balances must be exactly 0 (checked in tests and shown as a warning in the UI if it ever is not).
- **Fair rounding.** 10,00 EUR between 3 people is `334 / 333 / 333`: everyone gets the floor, the leftover cents go one by one to participants sorted by user id. Same input, same result, every time (`lib/domain/split.dart`).
- **Debt simplification** (`lib/domain/debt_simplifier.dart`): greedy matching of the largest debtor with the largest creditor. At most `n - 1` transfers and the transfers zero out every balance exactly. Finding the true minimum is NP-hard; greedy is good enough in practice and easy to reason about.
- **Pure domain layer.** Everything in `lib/domain/` is plain Dart with no Flutter or Supabase imports, so it is fast to test. 67 unit tests cover money, splits, balances, simplification, monthly summaries and search.
- **Privacy is enforced in the database (Row Level Security), not just in the app.** The app checks as well, but a modified client still cannot read another group's data. Writes that must stay consistent (saving an expense with its shares, recording a settlement, leaving a group) go through `security definer` RPCs that validate membership, totals and roles on the server. RLS isolation was tested on a throwaway PostgreSQL with a fake `auth` layer: other groups' rows are invisible and outsiders cannot add expenses.
- **No backend code.** Flutter talks to Supabase directly. A Python service is planned only for receipt reading (V2).
- **No third-party tracking.** No analytics. The UI font is bundled with the app instead of loaded from a font CDN.

## Architecture

```
lib/
  main.dart
  core/       supabase client, money, router, theme, shared widgets
  l10n/       app_de.arb, app_en.arb, app_tr.arb
  features/   auth, groups, shopping_list, expenses, catalog, balances, settings
              each: data/ (Supabase access), providers/ (Riverpod), ui/
  domain/     debt_simplifier, split, balance, monthly_summary (pure Dart)
test/
supabase/schema.sql   tables, RLS policies, RPC functions
docs/                 SPEC.md (rules), PLAN.md (plan and progress)
```

Stack: Flutter, `supabase_flutter` (PostgreSQL, Auth, Realtime, RLS), `flutter_riverpod`, `go_router` (path-based URLs, so invite links work), `intl` + generated localizations.

## Run locally

Requirements: Flutter, a Supabase project with [`supabase/schema.sql`](supabase/schema.sql) executed in the SQL Editor.

```
copy env.example.json env.json      # then fill in your Supabase URL and anon key
flutter pub get
flutter run -d chrome --dart-define-from-file=env.json
```

```
flutter analyze
flutter test
```

Use only the public `anon` (publishable) key in `env.json`. Never commit `env.json` or any Supabase `service_role` key.

## Project docs

- [`docs/SPEC.md`](docs/SPEC.md): how it works (rules, screens, edge cases)
- [`docs/PLAN.md`](docs/PLAN.md): weekly plan, progress and V2 roadmap
- [`supabase/schema.sql`](supabase/schema.sql): database schema, access rules, functions
- [`docs/GIZLILIK-ENVANTERI.md`](docs/GIZLILIK-ENVANTERI.md): technical data inventory (Turkish)

## Status and roadmap

V1 (web) is feature complete and being polished. Not deployed yet. See the checkboxes in [`docs/PLAN.md`](docs/PLAN.md).

Planned next: deployment with a permanent domain, in-app account deletion, recurring expenses (rent, internet), receipt photo reading with a small Python (FastAPI) service, Android release, iOS release via cloud macOS builds.
