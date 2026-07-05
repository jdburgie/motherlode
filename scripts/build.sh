#!/usr/bin/env bash
set -euo pipefail

CONFIGURATION="${1:-Debug}"
CHECKS="${2:-Enabled}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

require_command() {
    command -v "$1" >/dev/null 2>&1 || {
        echo "Required command '$1' was not found on PATH." >&2
        exit 1
    }
}

require_command git
require_command gprbuild
require_command arm-eabi-objcopy
require_command python3

git submodule sync --recursive
git submodule update --init --recursive

verify_dependency() {
    local path="$1"
    local expected="$2"
    local actual
    actual="$(git -C "$path" rev-parse HEAD)"
    if [[ "$actual" != "$expected" ]]; then
        echo "Dependency $path is at $actual; expected $expected." >&2
        exit 1
    fi
}

verify_dependency vendor/pygamer-bsp 2dba1dd3a9d9e8d5d5e441bdac37242a56ae048d
verify_dependency vendor/samd51-hal 3edd815bab9a8a4df15bd459f679a2465a9208ac
verify_dependency vendor/cortex-m 8c24b76979aa7fb86019006111007f4272dfe89c
verify_dependency vendor/hal 92eb1f60b352230352c41137b6983d0bb5e1b7ff
verify_dependency vendor/geste 9e99f066c49b3fccd02420b899d8ef95eeb0eb1b
verify_dependency vendor/virtapu bc5b7bf6cace9637208662e0dafb0b5c72b603f6
verify_dependency vendor/uf2 90e9741f217f5a40c98ba74d663e408041037578

VENDOR_PATHS=(
    "$ROOT/vendor/hal"
    "$ROOT/vendor/cortex-m"
    "$ROOT/vendor/samd51-hal"
    "$ROOT/vendor/pygamer-bsp"
    "$ROOT/vendor/geste"
    "$ROOT/vendor/virtapu"
)

JOINED_PATHS="$(IFS=:; echo "${VENDOR_PATHS[*]}")"
if [[ -n "${GPR_PROJECT_PATH:-}" ]]; then
    export GPR_PROJECT_PATH="$JOINED_PATHS:$GPR_PROJECT_PATH"
else
    export GPR_PROJECT_PATH="$JOINED_PATHS"
fi

gprbuild -p -P "$ROOT/motherlode.gpr" \
    "-XMOTHERLODE_BUILD=$CONFIGURATION" \
    "-XMOTHERLODE_BUILD_CHECKS=$CHECKS"

ELF="$ROOT/obj_target/motherlode.elf"
BIN="$ROOT/build/motherlode.bin"
UF2="$ROOT/build/motherlode.uf2"
mkdir -p "$ROOT/build"

arm-eabi-objcopy -O binary "$ELF" "$BIN"
python3 "$ROOT/vendor/uf2/utils/uf2conv.py" \
    -c -b 0x4000 -f SAMD51 -o "$UF2" "$BIN"

echo "ELF image: $ELF"
echo "Binary image: $BIN"
echo "UF2 image: $UF2"
