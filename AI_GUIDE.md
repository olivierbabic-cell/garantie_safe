# AI Guide (Garantie Safe)

Rules:
- Do NOT refactor folder structure or rename files unless explicitly requested.
- Do NOT add new dependencies without asking first.
- Keep changes small and reviewable: one task per commit.
- Do NOT rename existing l10n keys; only add new keys if needed.
- Single source of truth for SQLite is lib/core/db/app_db.dart (AppDb).
- Items must match AppDb schema (items.id is INTEGER AUTOINCREMENT; dates are purchase_date/expiry_date; attachments are in item_attachments table).
- After each change: app must build and run (no red errors).
