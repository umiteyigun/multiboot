#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

DISK_ID=""
AUTO_SELECT=1
SKIP_CONFIRM=1
COPY_ISOS=1
INSTALL_VENTOY=1
MOUNT_PATH=""

usage() {
  cat <<'EOF'
Kullanim:
  ./full_auto.sh [--disk disk4|sdb] [--no-copy] [--no-install] [--mount /path] [--interactive]

Ne yapar:
  1) Isletim sistemini tespit eder
  2) Docker image build eder
  3) Docker icinde prepare/manage/verify calistirir
  4) OS'e gore kurulum/kopyalama adimlarini otomatik uygular

Parametreler:
  --disk         Hedef disk (macOS: disk4, Linux: sdb)
  --no-copy      ISO kopyalama adimini kapat
  --no-install   Ventoy kurulum adimini kapat
  --mount        Linux'ta ISO kopyalama mount path
  --interactive  --yes ve --auto davranisini kapatir
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --disk)
      DISK_ID="${2:-}"
      shift 2
      ;;
    --no-copy)
      COPY_ISOS=0
      shift
      ;;
    --no-install)
      INSTALL_VENTOY=0
      shift
      ;;
    --mount)
      MOUNT_PATH="${2:-}"
      shift 2
      ;;
    --interactive)
      AUTO_SELECT=0
      SKIP_CONFIRM=0
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

OS_NAME="$(uname -s)"
echo "Tespit edilen OS: ${OS_NAME}"

if ! command -v docker >/dev/null 2>&1; then
  echo "Hata: docker bulunamadi." >&2
  exit 1
fi

if [[ "${OS_NAME}" == "Linux" ]]; then
  echo "Linux modu: Ventoy kurulum + ISO kopyalama Docker uzerinden otomatik."
  CMD=( "${ROOT_DIR}/docker-run.sh" )
  [[ ${INSTALL_VENTOY} -eq 1 ]] && CMD+=( --install-ventoy )
  [[ ${COPY_ISOS} -eq 1 ]] && CMD+=( --copy-isos )
  [[ -n "${DISK_ID}" ]] && CMD+=( --disk "${DISK_ID}" )
  [[ ${AUTO_SELECT} -eq 1 ]] && CMD+=( --auto )
  [[ ${SKIP_CONFIRM} -eq 1 ]] && CMD+=( --yes )
  [[ -n "${MOUNT_PATH}" ]] && CMD+=( --mount "${MOUNT_PATH}" )
  "${CMD[@]}"
  exit 0
fi

if [[ "${OS_NAME}" == "Darwin" ]]; then
  echo "macOS modu: Docker ile hazirlik, host'ta ISO kopyalama."
  echo "Not: Ventoy USB kurulumu macOS'ta otomatik desteklenmez."

  # 1) Docker icinde ortak adimlar
  "${ROOT_DIR}/docker-run.sh"

  # 2) Ventoy kurulum talebi varsa bilgi ver
  if [[ ${INSTALL_VENTOY} -eq 1 ]]; then
    echo
    echo "Ventoy kurulum adimi atlandi (macOS kisiti)."
    echo "Kurulumu bir kez Linux/Windows'ta yap, sonra macOS'tan ISO kopyalamaya devam et."
  fi

  # 3) ISO kopyalama (host macOS)
  if [[ ${COPY_ISOS} -eq 1 ]]; then
    echo
    echo "macOS host uzerinde ISO kopyalama adimi..."
    CMD=( "${ROOT_DIR}/copy_isos_to_usb.sh" )
    [[ -n "${DISK_ID}" ]] && CMD+=( --disk "${DISK_ID}" )
    "${CMD[@]}"
  else
    echo "ISO kopyalama kapali (--no-copy)."
  fi

  exit 0
fi

echo "Desteklenmeyen OS: ${OS_NAME}" >&2
exit 1
