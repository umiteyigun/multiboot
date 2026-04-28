#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENTOY_DIR="${ROOT_DIR}/tools/ventoy"

DISK_ID=""
AUTO_SELECT=0
SKIP_CONFIRM=0

usage() {
  cat <<'EOF'
Kullanim:
  ./install_ventoy_to_usb.sh [--disk disk4] [--auto] [--yes]

Aciklama:
  - USB diske Ventoy kurar.
  - Linux ortaminda Ventoy2Disk.sh ile otomatik kurulum yapar.
  - macOS'ta resmi Ventoy installer olmadigi icin bu script kurulum yapmaz.

Parametreler:
  --disk  Hedef disk (ornek: disk4 veya sdb)
  --auto  Tek harici disk varsa otomatik sec
  --yes   Son onayi atla
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
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

if [[ ! -x "${VENTOY_DIR}/Ventoy2Disk.sh" ]]; then
  echo "Hata: Ventoy2Disk.sh bulunamadi. Once ./prepare_ventoy.sh calistir." >&2
  exit 1
fi

OS_NAME="$(uname -s)"

if [[ "${OS_NAME}" == "Darwin" ]]; then
  cat <<'EOF'
Hata: macOS'ta Ventoy'yi USB'ye dogrudan kurmak icin resmi installer bulunmuyor.
Bu script Linux/Windows icin otomatik kurulum yapar.

Cozum:
  1) Linux (VM/LiveUSB) ac
  2) Bu klasorde su komutu calistir:
     ./install_ventoy_to_usb.sh --auto --yes
EOF
  exit 1
fi

if [[ "${OS_NAME}" != "Linux" ]]; then
  echo "Hata: Desteklenmeyen sistem: ${OS_NAME}" >&2
  exit 1
fi

list_external_linux_disks() {
  lsblk -dn -o NAME,TYPE,RM,TRAN | awk '$2=="disk" && ($3=="1" || $4=="usb") {print $1}'
}

if [[ -z "${DISK_ID}" ]]; then
  mapfile -t CANDIDATES < <(list_external_linux_disks)
  if [[ ${#CANDIDATES[@]} -eq 0 ]]; then
    echo "Hata: harici USB disk bulunamadi." >&2
    exit 1
  fi
  if [[ ${#CANDIDATES[@]} -eq 1 && ${AUTO_SELECT} -eq 1 ]]; then
    DISK_ID="${CANDIDATES[0]}"
    echo "Auto secim: ${DISK_ID}"
  else
    echo "USB diskler:"
    printf '  - %s\n' "${CANDIDATES[@]}"
    read -r -p "Hedef disk (ornek sdb): " DISK_ID
  fi
fi

TARGET="/dev/${DISK_ID}"
if [[ ! -b "${TARGET}" ]]; then
  echo "Hata: gecersiz disk: ${TARGET}" >&2
  exit 1
fi

echo
echo "Ventoy kurulum plani:"
echo "  Hedef disk: ${TARGET}"
echo "UYARI: Bu diskteki tum veriler silinir."

if [[ ${SKIP_CONFIRM} -ne 1 ]]; then
  read -r -p "Devam etmek icin 'YES' yaz: " CONFIRM
  if [[ "${CONFIRM}" != "YES" ]]; then
    echo "Iptal edildi."
    exit 1
  fi
fi

echo "Ventoy kuruluyor..."
sudo "${VENTOY_DIR}/Ventoy2Disk.sh" -I "${TARGET}"
echo "Ventoy kurulumu tamamlandi."
