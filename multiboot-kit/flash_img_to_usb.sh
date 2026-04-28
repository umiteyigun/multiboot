#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Kullanim:
  ./flash_img_to_usb.sh --image /tam/yol/dosya.img [--disk disk4] [--auto] [--yes]

Aciklama:
  - macOS'ta bir .img dosyasini USB diske yazar.
  - Varsayilan olarak sadece external (harici) diskleri listeler.
  - --auto: tek bir external disk varsa otomatik secer.
  - --yes: son onayi atlar (tehlikeli).

Ornek:
  ./flash_img_to_usb.sh --image ./build/arc.img --auto --yes
EOF
}

IMAGE_PATH=""
DISK_ID=""
AUTO_SELECT=0
SKIP_CONFIRM=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --image)
      IMAGE_PATH="${2:-}"
      shift 2
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

if [[ -z "${IMAGE_PATH}" ]]; then
  echo "Hata: --image zorunlu." >&2
  usage
  exit 1
fi

if [[ ! -f "${IMAGE_PATH}" ]]; then
  echo "Hata: imaj bulunamadi: ${IMAGE_PATH}" >&2
  exit 1
fi

if ! command -v diskutil >/dev/null 2>&1; then
  echo "Hata: Bu script macOS icin tasarlandi (diskutil gerekli)." >&2
  exit 1
fi

list_external_disks() {
  diskutil list | awk '
    /^\/dev\/disk[0-9]+ \(external/ {
      gsub("/dev/", "", $1);
      print $1;
    }
  '
}

if [[ -z "${DISK_ID}" ]]; then
  mapfile -t EXTERNAL_DISKS < <(list_external_disks)
  if [[ ${#EXTERNAL_DISKS[@]} -eq 0 ]]; then
    echo "Hata: external disk bulunamadi." >&2
    exit 1
  fi

  if [[ ${#EXTERNAL_DISKS[@]} -eq 1 && ${AUTO_SELECT} -eq 1 ]]; then
    DISK_ID="${EXTERNAL_DISKS[0]}"
    echo "Auto secim: ${DISK_ID}"
  else
    echo "External diskler:"
    printf '  - %s\n' "${EXTERNAL_DISKS[@]}"
    echo
    read -r -p "Hedef disk (ornek disk4): " DISK_ID
  fi
fi

if ! diskutil info "/dev/${DISK_ID}" >/dev/null 2>&1; then
  echo "Hata: gecersiz disk: ${DISK_ID}" >&2
  exit 1
fi

echo
echo "Yazma plani:"
echo "  Image : ${IMAGE_PATH}"
echo "  Disk  : /dev/${DISK_ID}"
echo
echo "UYARI: Hedef diskteki tum veriler silinir."

if [[ ${SKIP_CONFIRM} -ne 1 ]]; then
  read -r -p "Devam etmek icin 'YES' yaz: " CONFIRM
  if [[ "${CONFIRM}" != "YES" ]]; then
    echo "Iptal edildi."
    exit 1
  fi
fi

echo "Disk unmount ediliyor..."
diskutil unmountDisk "/dev/${DISK_ID}"

echo "Imaj yaziliyor (sudo gerekir)..."
sudo dd if="${IMAGE_PATH}" of="/dev/r${DISK_ID}" bs=4m status=progress
sync

echo "Tamamlandi. Son durum:"
diskutil list "/dev/${DISK_ID}"
