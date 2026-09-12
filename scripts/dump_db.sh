#!/usr/bin/env bash
#
# Snapshot the Sokabrain vault to docs/migration/sokabrain_vault_snapshot.sql,
# the file restore_db.sh restores by default.
#
# Usage:
#   ./scripts/dump_db.sh
#   DB_NAME=sokabrain_dev ./scripts/dump_db.sh
#   OUT=/tmp/vault.sql   ./scripts/dump_db.sh
#
# Admin credentials are scrubbed on the way out. The `admins` rows themselves
# have to stay, because competition_editions.published_by points at them and a
# restore fails on the foreign key without them -- but the email, display name
# and password hash are replaced with placeholders that cannot be logged into.
# Provision a real account after restoring with `npm run admin:create`.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT="${OUT:-$REPO_ROOT/docs/migration/sokabrain_vault_snapshot.sql}"

DB_NAME="${DB_NAME:-sokabrain}"
PGHOST="${PGHOST:-127.0.0.1}"
PGPORT="${PGPORT:-5432}"
PGUSER="${PGUSER:-$(whoami)}"
export PGHOST PGPORT PGUSER

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

echo "==> dumping $PGUSER@$PGHOST:$PGPORT/$DB_NAME"
pg_dump --no-owner --no-privileges -d "$DB_NAME" -f "$WORK/raw.sql"

echo "==> scrubbing admin credentials"
python3 - "$WORK/raw.sql" "$OUT" <<'PY'
import sys

src, dst = sys.argv[1], sys.argv[2]
out, in_admins, scrubbed = [], False, 0

for line in open(src):
    if line.startswith("COPY public.admins "):
        in_admins = True
        out.append(line)
        continue
    if in_admins:
        if line.startswith("\\."):
            in_admins = False
            out.append(line)
            continue
        # id, email, password_hash, display_name, is_active, created_at, last_login_at
        f = line.rstrip("\n").split("\t")
        if len(f) >= 4:
            f[1] = f"admin{f[0]}@example.invalid"
            f[2] = "scrubbed-not-a-valid-hash"
            f[3] = "Scrubbed Admin"
            if len(f) >= 7:
                f[6] = "\\N"
            scrubbed += 1
        out.append("\t".join(f) + "\n")
        continue
    out.append(line)

open(dst, "w").writelines(out)
print(f"    {scrubbed} admin row(s) scrubbed")
PY

echo "==> verifying no credential material survived"
if grep -qE '\$scrypt\$|\$argon2|\$2[aby]\$' "$OUT"; then
  echo "error: the snapshot still contains something that looks like a password hash" >&2
  exit 1
fi

echo "==> wrote $OUT ($(wc -c < "$OUT" | tr -d ' ') bytes)"
