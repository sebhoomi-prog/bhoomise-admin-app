#!/usr/bin/env bash
set -euo pipefail

# Split current monorepo into:
# - bhoomise-customer-app
# - bhoomise-vendor-app
# - bhoomise-admin-app
# - bhoomise-shared
#
# Defaults to dry-run mode.
# Use --apply to perform actual copy.
#
# Example:
#   bash scripts/split_into_role_repos.sh --dest "/Users/adityapal/StudioProjects" --apply

SRC_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEST_PARENT=""
APPLY=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dest)
      DEST_PARENT="${2:-}"
      shift 2
      ;;
    --apply)
      APPLY=1
      shift
      ;;
    *)
      echo "Unknown arg: $1"
      exit 1
      ;;
  esac
done

if [[ -z "$DEST_PARENT" ]]; then
  echo "Usage: $0 --dest <parent-folder> [--apply]"
  exit 1
fi

if [[ ! -d "$SRC_ROOT" ]]; then
  echo "Source root not found: $SRC_ROOT"
  exit 1
fi

if [[ ! -d "$DEST_PARENT" ]]; then
  echo "Destination parent folder not found: $DEST_PARENT"
  exit 1
fi

CUSTOMER_REPO="$DEST_PARENT/bhoomise-customer-app"
VENDOR_REPO="$DEST_PARENT/bhoomise-vendor-app"
ADMIN_REPO="$DEST_PARENT/bhoomise-admin-app"
SHARED_REPO="$DEST_PARENT/bhoomise-shared"

RSYNC_FLAGS=(-av --prune-empty-dirs --relative)
if [[ "$APPLY" -eq 0 ]]; then
  RSYNC_FLAGS+=(--dry-run)
fi

copy_paths() {
  local target="$1"
  shift
  mkdir -p "$target"
  (
    cd "$SRC_ROOT"
    rsync "${RSYNC_FLAGS[@]}" "$@" "$target/"
  )
}

echo "Source: $SRC_ROOT"
echo "Dest parent: $DEST_PARENT"
if [[ "$APPLY" -eq 0 ]]; then
  echo "Mode: DRY-RUN (no files will be copied)"
else
  echo "Mode: APPLY (files will be copied)"
fi
echo

# Shared base for all 3 apps
COMMON_APP_PATHS=(
  "./pubspec.yaml"
  "./README.md"
  "./firebase.json"
  "./firestore.rules"
  "./firestore.indexes.json"
  "./lib/main.dart"
  "./lib/firebase_options.dart"
  "./lib/config/***"
  "./lib/core/***"
  "./lib/features/auth/***"
  "./lib/features/profile/***"
  "./lib/features/splash/***"
  "./lib/app/***"
  "./assets/mock_api/ui/***"
  "./android/***"
  "./ios/***"
)

CUSTOMER_EXTRA=(
  "./lib/apps/customer/***"
  "./lib/modules/customer/***"
)

VENDOR_EXTRA=(
  "./lib/apps/vendor/***"
  "./lib/modules/vendor/***"
)

ADMIN_EXTRA=(
  "./lib/apps/admin/***"
  "./lib/modules/admin/***"
  "./assets/mock_api/admin/***"
)

SHARED_PATHS=(
  "./lib/shared/firebase/repositories/***"
)

echo "== Customer repo =="
copy_paths "$CUSTOMER_REPO" "${COMMON_APP_PATHS[@]}" "${CUSTOMER_EXTRA[@]}"
echo

echo "== Vendor repo =="
copy_paths "$VENDOR_REPO" "${COMMON_APP_PATHS[@]}" "${VENDOR_EXTRA[@]}"
echo

echo "== Admin repo =="
copy_paths "$ADMIN_REPO" "${COMMON_APP_PATHS[@]}" "${ADMIN_EXTRA[@]}"
echo

echo "== Shared repo =="
copy_paths "$SHARED_REPO" "${SHARED_PATHS[@]}"
echo

cat <<'EOF'
Done.

Next steps after copy (in each new app repo):
1) Remove non-role modules/apps not needed in that repo.
2) Prune routes in lib/app/routes/app_pages.dart and app_routes.dart.
3) Prune unused bindings in lib/app/bindings/.
4) Update pubspec.yaml assets and dependencies.
5) Run:
   flutter pub get
   dart analyze

Recommended workflow:
- Run dry-run first (default).
- Re-run with --apply once output looks correct.
EOF

