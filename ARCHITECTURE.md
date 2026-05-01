# Architecture Snapshot – Garantie Safe

## Database (Single Source of Truth)
- SQLite file: garantie_safe.db
- Central access: lib/core/db/app_db.dart (AppDb)
- Schema version: 2

### Table: items
- id INTEGER PRIMARY KEY AUTOINCREMENT
- title TEXT NOT NULL
- merchant TEXT
- category_code TEXT
- purchase_date INTEGER NOT NULL
- expiry_date INTEGER
- payment_method_code TEXT
- notes TEXT
- created_at INTEGER NOT NULL
- updated_at INTEGER NOT NULL

### Table: item_attachments
- id INTEGER PRIMARY KEY AUTOINCREMENT
- item_id INTEGER NOT NULL (FK -> items.id ON DELETE CASCADE)
- path TEXT NOT NULL
- type TEXT NOT NULL
- original_name TEXT
- sort_order INTEGER NOT NULL DEFAULT 0
- created_at INTEGER NOT NULL
- One item can have multiple attachments (1:n).

## Architectural Rules
- AppDb is the only database entry point.
- No feature-specific database implementations.
- Features must adapt to this schema, not the other way around.
- Migrations must be handled inside AppDb.
