#!/usr/bin/env bash
#
# Restore the migrated Sokabrain vault dump into a fresh Postgres database.
#
# Usage:
#   ./scripts/restore_db.sh                  # restore into local db "sokabrain"
#   DB_NAME=sokabrain_dev ./scripts/restore_db.sh
#   TARGET_URL=postgres://user:pw@host/db ./scripts/restore_db.sh   # e.g. Neon/Railway
#   FORCE=1 ./scripts/restore_db.sh          # drop and recreate if it already exists
#
# Safe by default: refuses to touch a database that already exists unless FORCE=1.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DUMP="$REPO_ROOT/docs/migration/sokabrain_vault_migrated.sql"

DB_NAME="${DB_NAME:-sokabrain}"
PGHOST="${PGHOST:-127.0.0.1}"
PGPORT="${PGPORT:-5432}"
PGUSER="${PGUSER:-$(whoami)}"
TARGET_URL="${TARGET_URL:-}"
FORCE="${FORCE:-0}"

[ -f "$DUMP" ] || { echo "error: dump not found at $DUMP" >&2; exit 1; }

# The dump was produced by pg_dump 16.15, which emits the \restrict / \unrestrict
# meta-commands. psql older than 16.10 does not understand them and aborts under
# ON_ERROR_STOP. They carry no schema or data, so strip them before restoring.
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
grep -vE '^\\(un)?restrict ' "$DUMP" > "$WORK/restore.sql"

if [ -n "$TARGET_URL" ]; then
  echo "==> restoring into remote target"
  PSQL=(psql "$TARGET_URL")
else
  echo "==> target: $PGUSER@$PGHOST:$PGPORT/$DB_NAME"
  export PGHOST PGPORT PGUSER
  exists="$(psql -d postgres -tAc "select 1 from pg_database where datname='$DB_NAME'")"
  if [ "$exists" = "1" ]; then
    if [ "$FORCE" = "1" ]; then
      echo "==> dropping existing database $DB_NAME (FORCE=1)"
      dropdb --force "$DB_NAME"
    else
      echo "error: database '$DB_NAME' already exists. Re-run with FORCE=1 to replace it." >&2
      exit 1
    fi
  fi
  createdb "$DB_NAME"
  echo "==> created database $DB_NAME"
  PSQL=(psql -d "$DB_NAME")
fi

# --single-transaction so a partial failure leaves nothing behind.
"${PSQL[@]}" -v ON_ERROR_STOP=1 --single-transaction -q -f "$WORK/restore.sql"

echo "==> restore complete. Row counts:"
"${PSQL[@]}" -P pager=off -c \
  "SELECT relname AS table, n_live_tup AS rows FROM pg_stat_user_tables ORDER BY n_live_tup DESC, relname;"
