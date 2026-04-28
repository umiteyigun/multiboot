#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ISOS_DIR="${ROOT_DIR}/isos"

DISK_ID=""
MOUNT_PATH=""

usage() {
  cat <<'EOF'
Kullanim:
  ./copy_isos_to_usb.sh [--disk disk4] [--mount /path]

Aciklama:
  - isos/ altindaki tum .iso dosyalarini Ventoy USB veri bolumune kopyalar.
  - macOS'ta disk verildiginde /dev/diskXs1 baglanip kopyalanir.
  - Linux'ta --mount ile mounted hedef path verilmesi onerilir.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --disk)
      DISK_ID="${2:-}"
      shift 2
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

if [[ ! -d "${ISOS_DIR}" ]]; then
  echo "Hata: isos klasoru yok: ${ISOS_DIR}" >&2
  exit 1
fi

shopt -s nullglob
ISO_FILES=("${ISOS_DIR}"/*.iso)
shopt -u nullglob
if [[ ${#ISO_FILES[@]} -eq 0 ]]; then
  echo "Kopyalanacak ISO yok: ${ISOS_DIR}"
  exit 0
fi

OS_NAME="$(uname -s)"

if [[ -z "${MOUNT_PATH}" ]]; then
  if [[ "${OS_NAME}" == "Darwin" ]]; then
    if [[ -z "${DISK_ID}" ]]; then
      read -r -p "Ventoy USB disk id (ornek disk4): " DISK_ID
    fi
    echo "Ventoy veri bolumu baglaniyor: /dev/${DISK_ID}s1"
    diskutil mount "/dev/${DISK_ID}s1" >/dev/null
    MOUNT_PATH="/Volumes/Ventoy"
  else
    echo "Hata: Linux icin --mount /media/... vermelisin." >&2
    exit 1
  fi
fi

if [[ ! -d "${MOUNT_PATH}" ]]; then
  echo "Hata: mount path bulunamadi: ${MOUNT_PATH}" >&2
  exit 1
fi

echo "ISO dosyalari kopyalaniyor -> ${MOUNT_PATH}"
for iso in "${ISO_FILES[@]}"; do
  cp -f "${iso}" "${MOUNT_PATH}/"
  echo "  + $(basename "${iso}")"
done
sync
echo "Kopyalama tamam."
