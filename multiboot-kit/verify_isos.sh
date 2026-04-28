#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ISOS_DIR="${ROOT_DIR}/isos"
MANIFEST="${ROOT_DIR}/iso-manifest.sha256"

if [[ ! -d "${ISOS_DIR}" ]]; then
  echo "ISO klasoru bulunamadi: ${ISOS_DIR}" >&2
  exit 1
fi

shopt -s nullglob
ISO_FILES=("${ISOS_DIR}"/*.iso)
shopt -u nullglob

if [[ ${#ISO_FILES[@]} -eq 0 ]]; then
  echo "isos/ klasorunde ISO yok."
  exit 0
fi

echo "Bulunan ISO dosyalari:"
for iso in "${ISO_FILES[@]}"; do
  ls -lh "${iso}"
done

echo
echo "SHA256 ozetleri:"
for iso in "${ISO_FILES[@]}"; do
  shasum -a 256 "${iso}"
done

echo
if [[ -f "${MANIFEST}" ]]; then
  echo "Manifest bulundu: ${MANIFEST}"
  echo "Manifest dogrulamasi:"
  (
    cd "${ISOS_DIR}"
    shasum -a 256 -c "${MANIFEST}"
  )
else
  echo "Not: Manifest yok. Uretmek icin once ./manage_isos.sh calistir."
fi
