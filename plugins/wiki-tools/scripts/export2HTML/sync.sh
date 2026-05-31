#!/usr/bin/env bash
#
# Deploy wiki: Quartz build + lftp upload (explicit FTPS)
#
# Použití:
#   deploy.sh <slug> [vault-name]
#
set -euo pipefail

# ── KONFIGURACE ─────────────────────────────────────────────────────
QUARTZ_DIR="/Users/michalblaha/Documents/Dev/Dev Projects/quartz"
VAULTS_BASE="$HOME/Documents/Wikis"
EXPORT_BASE="$HOME/Documents/Wikis/_export"
REMOTE_BASE="/wikis/hlidac-secure-wikis"

REMOTE_HOST="10.10.100.103:21"
REMOTE_USER="michal"
KEYCHAIN_SERVICE="ftps-esel"
# ────────────────────────────────────────────────────────────────────

# Zapamatuj si výchozí adresář a vrať se do něj při ukončení (i při chybě)
ORIGINAL_DIR="$PWD"
trap 'cd "$ORIGINAL_DIR"' EXIT

usage() {
  cat <<EOF >&2
Použití: $(basename "$0") <slug> [vault-name]

  slug        Adresář v _export/ a na vzdáleném serveru (např. "esel")
  vault-name  Název vault složky pod $VAULTS_BASE/
              Volitelné, default = slug.

Příklady:
  $(basename "$0") esel eSel
  $(basename "$0") hlidac
EOF
  exit 1
}

case "${1:-}" in
  ""|-h|--help) usage ;;
esac

SLUG="$1"
VAULT_NAME="${2:-$SLUG}"

VAULT="$VAULTS_BASE/$VAULT_NAME"
EXPORT="$EXPORT_BASE/$SLUG"
REMOTE_DIR="$REMOTE_BASE/$SLUG"

[[ -d "$VAULT" ]]      || { echo "❌ Vault neexistuje: $VAULT" >&2; exit 1; }
[[ -d "$QUARTZ_DIR" ]] || { echo "❌ Quartz adresář neexistuje: $QUARTZ_DIR" >&2; exit 1; }

echo "▸ Slug:   $SLUG"
echo "▸ Vault:  $VAULT"
echo "▸ Export: $EXPORT"
echo "▸ Remote: ftps://$REMOTE_HOST$REMOTE_DIR"
echo

echo "▸ Build Quartz"
cd "$QUARTZ_DIR"
mkdir -p "$(dirname "$EXPORT")"
npx quartz build -d "$VAULT/wiki" -o "$EXPORT"

echo
echo "▸ Upload"
HESLO=$(security find-generic-password -s "$KEYCHAIN_SERVICE" -a "$REMOTE_USER" -w)

lftp -e "
  set ftp:ssl-force true;
  set ftp:ssl-protect-data true;
  set ftp:ssl-allow yes;
  set ssl:verify-certificate no;
  set ftp:passive-mode on;
  set net:timeout 20;
  set net:max-retries 3;
  set net:reconnect-interval-base 5;
  set xfer:clobber on;
  open -u $REMOTE_USER,'$HESLO' ftp://$REMOTE_HOST;
  mirror --reverse --delete --only-newer --parallel=4 \
    --no-perms \
    --exclude-glob '*.bak' \
    --exclude-glob '.DS_Store' \
    --exclude-glob '.git/' \
    --verbose \
    '$EXPORT' '$REMOTE_DIR';
  bye
"

echo
echo "✓ Hotovo: $SLUG"