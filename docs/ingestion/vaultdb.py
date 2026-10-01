"""Where the ingestion scripts find the vault database.

Every loader imports DSN from here instead of hardcoding its own. Set
DATABASE_URL to point them somewhere else -- the same variable the backend
reads from backend/.env, e.g.

    DATABASE_URL=postgresql://me@127.0.0.1:5432/sokabrain python3 load.py

Unset, it falls back to a local database named "sokabrain" as the current OS
user, which is what ./scripts/restore_db.sh creates by default.
"""
import os

DSN = os.environ.get("DATABASE_URL") or "host=127.0.0.1 port=5432 dbname=sokabrain"
