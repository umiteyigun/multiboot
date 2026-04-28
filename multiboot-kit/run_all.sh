#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

INSTALL_VENTOY=0
COPY_ISOS=0
AUTO_SELECT=0
SKIP_CONFIRM=0
DISK_ID=""
MOUNT_PATH=""

usage() {
  cat <<'EOF'
Kullanim:
  ./run_all.sh [--install-ventoy] [--copy-isos] [--disk disk4] [--auto] [--yes] [--mount /path]

Akis:
  1) prepare_ventoy.sh
  2) manage_isos.sh
  3) verify_isos.sh
  4) (opsiyonel) install_ventoy_to_usb.sh
  5) (opsiyonel) copy_isos_to_usb.sh

Parametreler:
  --install-ventoy Ventoy kurulum adimini ac
  --copy-isos      ISO dosyalarini Ventoy USB'ye kopyala
  --disk           Hedef disk (ornek: disk4 veya sdb)
  --auto           Tek external disk varsa otomatik sec
  --yes            Kurulum onayini atla
  --mount          ISO kopyalama icin mount path (Linux)
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --install-ventoy)
      INSTALL_VENTOY=1
      shift
      ;;
    --copy-isos)
      COPY_ISOS=1
      shift
      ;;
    --disk)
      DISK_ID="${2:-}"
      shift 2
      ;;
    --auto)
      AUTO_SELECT=1
      shift
      ;;
    --yes)
      SKIP_CONFIRM=1
      shift
      ;;
    --mount)
      MOUNT_PATH="${2:-}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Bilinmeyen arguman: $1" >&2
      usage
      exit 1
      ;;
  esac
done

echo "[1/5] Ventoy hazirlik..."
"${ROOT_DIR}/prepare_ventoy.sh"

echo "[2/5] ISO yonetimi..."
"${ROOT_DIR}/manage_isos.sh"

echo "[3/5] ISO dogrulama..."
"${ROOT_DIR}/verify_isos.sh"

if [[ ${INSTALL_VENTOY} -eq 1 ]]; then
  echo "[4/5] Ventoy USB kurulumu..."
  CMD=( "${ROOT_DIR}/install_ventoy_to_usb.sh" )
  [[ -n "${DISK_ID}" ]] && CMD+=( --disk "${DISK_ID}" )
  [[ ${AUTO_SELECT} -eq 1 ]] && CMD+=( --auto )
  [[ ${SKIP_CONFIRM} -eq 1 ]] && CMD+=( --yes )
  "${CMD[@]}"
else
  echo "[4/5] Ventoy kurulumu atlandi. (--install-ventoy ile acabilirsin)"
fi

if [[ ${COPY_ISOS} -eq 1 ]]; then
  echo "[5/5] ISO dosyalari USB'ye kopyalaniyor..."
  CMD=( "${ROOT_DIR}/copy_isos_to_usb.sh" )
  [[ -n "${DISK_ID}" ]] && CMD+=( --disk "${DISK_ID}" )
  [[ -n "${MOUNT_PATH}" ]] && CMD+=( --mount "${MOUNT_PATH}" )
  "${CMD[@]}"
else
  echo "[5/5] ISO kopyalama atlandi. (--copy-isos ile acabilirsin)"
fi
