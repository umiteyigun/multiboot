#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOLS_DIR="${ROOT_DIR}/tools"
ISOS_DIR="${ROOT_DIR}/isos"
TMP_DIR="${ROOT_DIR}/tmp"

VENTOY_VERSION="${VENTOY_VERSION:-}"

resolve_release() {
  local api_json tag
  api_json="$(curl -fsSL "https://api.github.com/repos/ventoy/Ventoy/releases/latest")"
  tag="$(echo "${api_json}" | jq -r '.tag_name')"
  if [[ -z "${tag}" || "${tag}" == "null" ]]; then
    echo "Hata: Ventoy latest release bilgisi alinamadi." >&2
    exit 1
  fi
  echo "${api_json}" > "${TMP_DIR}/latest-release.json"
  echo "${tag#v}"
}

require_cmd() {
  local cmd="$1"
  if ! command -v "${cmd}" >/dev/null 2>&1; then
    echo "Hata: '${cmd}' komutu bulunamadi." >&2
    exit 1
  fi
}

mkdir -p "${TOOLS_DIR}" "${ISOS_DIR}" "${TMP_DIR}"
require_cmd curl
require_cmd jq
require_cmd tar

if [[ -z "${VENTOY_VERSION}" ]]; then
  VENTOY_VERSION="$(resolve_release)"
fi

VENTOY_FILE="ventoy-${VENTOY_VERSION}-linux.tar.gz"
VENTOY_URL="https://github.com/ventoy/Ventoy/releases/download/v${VENTOY_VERSION}/${VENTOY_FILE}"

echo "Ventoy indiriliyor: ${VENTOY_URL}"
curl -fL "${VENTOY_URL}" -o "${TMP_DIR}/${VENTOY_FILE}"

echo "Paket aciliyor..."
tar -xzf "${TMP_DIR}/${VENTOY_FILE}" -C "${TMP_DIR}"

EXTRACTED_DIR="${TMP_DIR}/ventoy-${VENTOY_VERSION}"
if [[ ! -d "${EXTRACTED_DIR}" ]]; then
  echo "Hata: Beklenen klasor bulunamadi: ${EXTRACTED_DIR}" >&2
  exit 1
fi

rm -rf "${TOOLS_DIR}/ventoy"
mv "${EXTRACTED_DIR}" "${TOOLS_DIR}/ventoy"

echo
echo "Hazir. Ventoy araci:"
echo "  ${TOOLS_DIR}/ventoy"
echo
echo "ISO klasoru:"
echo "  ${ISOS_DIR}"
echo
echo "USB'ye hicbir sey yazilmadi. Sadece hazirlik tamamlandi."
echo "Not: Son surumde resmi macOS paket yok; Linux Ventoy araci hazirlandi."
