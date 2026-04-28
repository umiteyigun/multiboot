#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ISOS_DIR="${ROOT_DIR}/isos"
MANIFEST="${ROOT_DIR}/iso-manifest.sha256"

if [[ ! -d "${ISOS_DIR}" ]]; then
  echo "ISO klasoru bulunamadi: ${ISOS_DIR}" >&2
  exit 1
fi

slugify_name() {
  local input="$1"
  local output
  output="$(echo "${input}" | tr '[:upper:]' '[:lower:]')"
  output="$(echo "${output}" | sed -E 's/[^a-z0-9._-]+/-/g; s/^-+//; s/-+$//; s/-+/-/g')"
  [[ -z "${output}" ]] && output="iso"
  echo "${output}"
}

shopt -s nullglob
ISO_FILES=("${ISOS_DIR}"/*.iso "${ISOS_DIR}"/*.ISO)
shopt -u nullglob

if [[ ${#ISO_FILES[@]} -eq 0 ]]; then
  echo "isos/ klasorunde ISO yok."
  exit 0
fi

echo "ISO adlari normalize ediliyor..."
for iso in "${ISO_FILES[@]}"; do
  base="$(basename "${iso}")"
  stem="${base%.*}"
  ext="${base##*.}"
  ext_lower="$(echo "${ext}" | tr '[:upper:]' '[:lower:]')"
  safe_stem="$(slugify_name "${stem}")"
  candidate="${safe_stem}.${ext_lower}"
  target="${ISOS_DIR}/${candidate}"

  if [[ "${iso}" == "${target}" ]]; then
    continue
  fi

  if [[ -e "${target}" ]]; then
    idx=1
    while [[ -e "${ISOS_DIR}/${safe_stem}-${idx}.${ext_lower}" ]]; do
      ((idx++))
    done
    target="${ISOS_DIR}/${safe_stem}-${idx}.${ext_lower}"
  fi

  echo "  ${base} -> $(basename "${target}")"
  mv "${iso}" "${target}"
done

echo
echo "Manifest uretiliyor: ${MANIFEST}"
(
  cd "${ISOS_DIR}"
  shopt -s nullglob
  ISO_FILES_FINAL=( *.iso )
  shopt -u nullglob
  for iso in "${ISO_FILES_FINAL[@]}"; do
    shasum -a 256 "${iso}"
  done | LC_ALL=C sort
) > "${MANIFEST}"

echo "Tamamlandi."
echo "Toplam ISO: $(wc -l < "${MANIFEST}" | tr -d ' ')"
