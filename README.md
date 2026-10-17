# WG App

> Work in progress. A shared-household app for flatmates (WG): **list what is missing, do the shopping, split the cost automatically.**

## What it does (V1 goal)

- **Shared shopping list** for things that ran out at home. Real-time, visible only to the group.
- **Expenses** entered by whoever paid: amount, who is covered, optional items. Equal, custom-amount or ratio splits.
- **Quick item picker:** ready-made catalog (German/English), search, and the group's most-used items.
- **Balances** and the fewest transfers needed to settle up. Handles flatmates moving in and out.
- German and English UI.

## Why not just Splitwise?

<!-- Fill in at the end of Week 6: list + expense flow in one place, WG-specific move-out handling, quick item picker. -->

## Tech stack

Flutter (Dart) for web first, later Android/iOS from the same code. Supabase (PostgreSQL, Auth, Realtime, Row Level Security) as the backend.

## Project docs

- [`docs/SPEC.md`](docs/SPEC.md): how it works (rules, screens, edge cases)
- [`docs/PLAN.md`](docs/PLAN.md): weekly plan and progress
- [`supabase/schema.sql`](supabase/schema.sql): database schema, access rules, functions

## Run locally

```
copy env.example.json env.json      # then fill in your Supabase URL and anon key
flutter pub get
flutter run -d chrome --dart-define-from-file=env.json
```

Never commit `env.json` or any Supabase `service_role` key.

## Status

See the checkboxes in [`docs/PLAN.md`](docs/PLAN.md).
