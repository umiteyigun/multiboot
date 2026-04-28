#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMAGE_NAME="${IMAGE_NAME:-multiboot-kit:latest}"

usage() {
  cat <<'EOF'
Kullanim:
  ./docker-run.sh [run_all.sh parametreleri]

Ornekler:
  # Sadece hazirlik + ISO yonetimi
  ./docker-run.sh

  # Linux host'ta Ventoy kur + ISO kopyala
  ./docker-run.sh --install-ventoy --copy-isos --auto --yes

Not:
  USB yazma/kurulum icin host tarafinda device erisimi gerekir.
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

echo "Docker image build: ${IMAGE_NAME}"
docker build -t "${IMAGE_NAME}" "${ROOT_DIR}"

RUN_ARGS=(
  --rm
  --privileged
  -v "${ROOT_DIR}:/workspace"
  -v /dev:/dev
  -v /run/udev:/run/udev:ro
  "${IMAGE_NAME}"
)

if [[ -t 0 && -t 1 ]]; then
  RUN_ARGS=( --rm -it --privileged -v "${ROOT_DIR}:/workspace" -v /dev:/dev -v /run/udev:/run/udev:ro "${IMAGE_NAME}" )
fi

echo "Container calisiyor..."
docker run "${RUN_ARGS[@]}" "$@"
